package com.flops23.assistae

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal fun json(vararg fields: Pair<String, Any?>) =
    JSONObject().apply { fields.forEach { (key, value) -> put(key, value ?: JSONObject.NULL) } }

internal fun JSONObject.text(key: String): String? =
    if (isNull(key)) null else optString(key).takeIf(String::isNotEmpty)

internal fun JSONObject.objects(key: String): List<JSONObject> =
    (optJSONArray(key) ?: JSONArray()).let { rows ->
        (0 until rows.length()).mapNotNull(rows::optJSONObject)
    }

internal fun JSONObject.data(): JSONObject = optJSONObject("data") ?: JSONObject()
internal fun JSONObject.revisions(): JSONObject = optJSONObject("revisions") ?: JSONObject()

internal class ApiFailure(val code: String, val httpStatus: Int = 0) : Exception(code)

internal data class AuthSession(val userId: String, val accessToken: String, val refreshToken: String, val expiresAt: Long)

internal class SupabaseClient(context: Context) {
    private val store = SessionStore(context)
    private val authMutex = Mutex()
    private var currentSession: AuthSession? = null
    private val endpoint = BuildConfig.SUPABASE_URL.toHttpUrl().also { require(it.isHttps) }
    private val publicKey = BuildConfig.SUPABASE_PUBLIC_KEY
    private val http = OkHttpClient.Builder()
        .followRedirects(false)
        .followSslRedirects(false)
        .retryOnConnectionFailure(false)
        .connectTimeout(8, TimeUnit.SECONDS)
        .callTimeout(12, TimeUnit.SECONDS)
        .build()

    suspend fun session(forceRefresh: Boolean = false): AuthSession = authMutex.withLock {
        withContext(Dispatchers.IO) {
            if (publicKey.isEmpty()) throw ApiFailure("APP_CONFIGURATION_MISSING")
            val old = currentSession ?: store.read()
            if (old != null && !forceRefresh && old.expiresAt > System.currentTimeMillis() / 1000 + 60) {
                currentSession = old
                return@withContext old
            }
            val (path, body) = if (old == null) {
                "auth/v1/signup" to json("data" to JSONObject())
            } else {
                "auth/v1/token?grant_type=refresh_token" to json("refresh_token" to old.refreshToken)
            }
            val payload = post(path, body, null)
            val id = payload.optJSONObject("user")?.text("id") ?: old?.userId
            val access = payload.text("access_token")
            val refresh = payload.text("refresh_token")
            val expiry = payload.optLong("expires_at", System.currentTimeMillis() / 1000 + payload.optLong("expires_in", 3600))
            if (id == null || access == null || refresh == null || (old != null && id != old.userId)) {
                throw ApiFailure("SESSION_UNAVAILABLE")
            }
            AuthSession(id, access, refresh, expiry).also {
                store.write(it)
                currentSession = it
            }
        }
    }

    suspend fun rpc(name: String, arguments: JSONObject = JSONObject()): JSONObject {
        val initial = session()
        val path = "rest/v1/rpc/" + name
        val response = try {
            withContext(Dispatchers.IO) { post(path, arguments, initial.accessToken) }
        } catch (failure: ApiFailure) {
            if (failure.httpStatus != 401 && failure.code != "UNAUTHENTICATED") throw failure
            val renewed = session(forceRefresh = true)
            withContext(Dispatchers.IO) { post(path, arguments, renewed.accessToken) }
        }
        response.text("code")?.let { throw ApiFailure(it) }
        return response
    }

    suspend fun runValidation(id: String, executionToken: String) = withContext(Dispatchers.IO) {
        post("functions/v1/media-validator", json("validation_id" to id, "execution_token" to executionToken), null)
    }

    fun invalidations(auth: AuthSession): Flow<Unit> = callbackFlow {
        val url = endpoint.newBuilder()
            .addPathSegments("realtime/v1/websocket")
            .addQueryParameter("apikey", publicKey)
            .addQueryParameter("vsn", "1.0.0")
            .build()
        val topic = "realtime:assistae:account:${auth.userId}"
        val sequence = AtomicLong()
        fun envelope(topicName: String, event: String, payload: JSONObject, ref: String) =
            json("topic" to topicName, "event" to event, "payload" to payload, "ref" to ref).toString()

        val request = Request.Builder().url(url).build()
        val socket = http.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                val options = json(
                    "private" to true,
                    "broadcast" to json("ack" to false, "self" to false),
                    "presence" to json("enabled" to false),
                    "postgres_changes" to JSONArray(),
                )
                webSocket.send(envelope(topic, "phx_join", json("config" to options, "access_token" to auth.accessToken), "1"))
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                val event = runCatching { JSONObject(text) }.getOrNull() ?: return
                if (event.optString("topic") != topic) return
                val payload = event.optJSONObject("payload") ?: return
                when (event.optString("event")) {
                    "phx_reply" -> if (event.optString("ref") == "1") {
                        if (payload.optString("status") == "ok") trySend(Unit) else close(ApiFailure("REALTIME_UNAVAILABLE"))
                    }
                    "broadcast" -> if (payload.optString("event") == "refresh") trySend(Unit)
                    "phx_error", "phx_close" -> close(ApiFailure("REALTIME_UNAVAILABLE"))
                }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) { close() }
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                close(ApiFailure("REALTIME_UNAVAILABLE"))
            }
        })
        val heartbeat = launch {
            while (true) {
                delay(20_000)
                if (auth.expiresAt < System.currentTimeMillis() / 1000 + 60) {
                    close()
                    break
                }
                if (!socket.send(envelope("phoenix", "heartbeat", JSONObject(), (sequence.incrementAndGet() + 1).toString()))) {
                    close()
                    break
                }
            }
        }
        awaitClose {
            heartbeat.cancel()
            socket.cancel()
        }
    }

    private fun post(path: String, body: JSONObject, accessToken: String?): JSONObject {
        val url = endpoint.resolve(path) ?: throw ApiFailure("APP_CONFIGURATION_MISSING")
        val request = Request.Builder().url(url)
            .header("apikey", publicKey)
            .apply { if (accessToken != null) header("Authorization", "Bearer " + accessToken) }
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()
        http.newCall(request).execute().use { response ->
            val content = response.body?.string().orEmpty()
            val payload = runCatching { JSONObject(content) }.getOrDefault(JSONObject())
            if (!response.isSuccessful) {
                throw ApiFailure(payload.text("error_code") ?: payload.text("code") ?: "NETWORK_RESPONSE_ERROR", response.code)
            }
            if (content.isEmpty()) throw ApiFailure("NETWORK_RESPONSE_ERROR")
            return payload
        }
    }
}

private class SessionStore(context: Context) {
    private val prefs = context.getSharedPreferences("identity", Context.MODE_PRIVATE)
    private val alias = "assistae.auth.v1"

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(
                KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build(),
            )
            generateKey()
        }
    }

    fun read(): AuthSession? {
        val encoded = prefs.getString("session", null) ?: return null
        try {
            val bytes = Base64.decode(encoded, Base64.NO_WRAP)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes.copyOfRange(0, 12)))
            val data = JSONObject(cipher.doFinal(bytes, 12, bytes.size - 12).decodeToString())
            return AuthSession(data.getString("id"), data.getString("access"), data.getString("refresh"), data.getLong("expires"))
        } catch (_: Exception) {
            throw ApiFailure("SESSION_UNAVAILABLE")
        }
    }

    fun write(session: AuthSession) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val data = json(
            "id" to session.userId,
            "access" to session.accessToken,
            "refresh" to session.refreshToken,
            "expires" to session.expiresAt,
        ).toString().encodeToByteArray()
        check(cipher.iv.size == 12)
        val sealed = Base64.encodeToString(cipher.iv + cipher.doFinal(data), Base64.NO_WRAP)
        if (!prefs.edit().putString("session", sealed).commit()) throw ApiFailure("SESSION_UNAVAILABLE")
    }
}
