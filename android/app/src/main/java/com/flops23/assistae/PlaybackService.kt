package com.flops23.assistae

import android.app.PendingIntent
import android.content.Intent
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.okhttp.OkHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.session.SessionResult
import okhttp3.Dns
import okhttp3.HttpUrl
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import java.io.IOException
import java.net.InetAddress
import java.net.Proxy
import java.net.UnknownHostException

internal object RoomMediaActions {
    var playPause: (() -> Unit)? = null
    var stopLocally: (() -> Unit)? = null
    var seek: ((Long) -> Unit)? = null
}

@OptIn(UnstableApi::class)
class PlaybackService : MediaSessionService() {
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        val http = OkHttpClient.Builder()
            .proxy(Proxy.NO_PROXY)
            .dns(object : Dns {
                override fun lookup(hostname: String): List<InetAddress> {
                    val addresses = Dns.SYSTEM.lookup(hostname)
                    if (addresses.isEmpty() || addresses.any { !isPublicMediaAddress(it) }) {
                        throw UnknownHostException("Destino de vídeo indisponível")
                    }
                    return addresses
                }
            })
            .followRedirects(false)
            .followSslRedirects(false)
            .addInterceptor(PublicMediaRedirects())
            .build()
        val factory = DefaultMediaSourceFactory(OkHttpDataSource.Factory(http))
        val player = ExoPlayer.Builder(this).setMediaSourceFactory(factory)
            .setAudioAttributes(AudioAttributes.DEFAULT, true)
            .setHandleAudioBecomingNoisy(true)
            .build()
        val activity = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        mediaSession = MediaSession.Builder(this, player)
            .setSessionActivity(activity)
            .setCallback(object : MediaSession.Callback {
                override fun onPlayerCommandRequest(session: MediaSession, controller: MediaSession.ControllerInfo, playerCommand: Int): Int {
                    if (controller.packageName == packageName) return SessionResult.RESULT_SUCCESS
                    when (playerCommand) {
                        Player.COMMAND_STOP -> {
                            RoomMediaActions.stopLocally?.invoke()
                            session.player.stop()
                            session.player.clearMediaItems()
                        }
                        Player.COMMAND_PLAY_PAUSE -> RoomMediaActions.playPause?.invoke()
                        Player.COMMAND_SEEK_BACK -> RoomMediaActions.seek?.invoke(-10_000)
                        Player.COMMAND_SEEK_FORWARD -> RoomMediaActions.seek?.invoke(10_000)
                    }
                    return SessionResult.RESULT_ERROR_NOT_SUPPORTED
                }
            })
            .build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = mediaSession

    override fun onTaskRemoved(rootIntent: Intent?) {
        RoomMediaActions.stopLocally?.invoke()
        mediaSession?.player?.stop()
        stopSelf()
    }

    override fun onDestroy() {
        mediaSession?.let {
            it.player.release()
            it.release()
        }
        mediaSession = null
        super.onDestroy()
    }
}

private class PublicMediaRedirects : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        var request = chain.request()
        repeat(4) { hop ->
            verifyMediaUrl(request.url)
            val response = chain.proceed(request)
            if (response.code !in setOf(301, 302, 303, 307, 308)) return response
            val location = response.header("Location")?.let(request.url::resolve)
            response.close()
            if (location == null || hop == 3) throw IOException("Redirecionamento de vídeo indisponível")
            request = request.newBuilder().url(location).build()
        }
        throw IOException("Redirecionamento de vídeo indisponível")
    }

    private fun verifyMediaUrl(url: HttpUrl) {
        if (url.port !in setOf(80, 443) || url.username.isNotEmpty() || url.password.isNotEmpty() ||
            url.host == "localhost" || url.host.endsWith(".local") || url.host.endsWith(".internal")
        ) throw IOException("Destino de vídeo indisponível")
    }
}

internal fun isPublicMediaAddress(address: InetAddress): Boolean {
    val bytes = address.address.map { it.toInt() and 255 }
    if (bytes.size == 4) {
        val (a, b, c) = bytes
        return !(a == 0 || a == 10 || a == 127 || a >= 224 ||
            (a == 100 && b in 64..127) || (a == 169 && b == 254) ||
            (a == 172 && b in 16..31) || (a == 192 && (b == 168 || (b == 0 && c in setOf(0, 2)) || (b == 88 && c == 99))) ||
            (a == 198 && (b in 18..19 || (b == 51 && c == 100))) || (a == 203 && b == 0 && c == 113))
    }
    if (bytes.size != 16) return false
    val first = (bytes[0] shl 8) + bytes[1]
    val second = (bytes[2] shl 8) + bytes[3]
    return first in 0x2000..0x3fff && first != 0x2002 &&
        !(first == 0x2001 && (second < 0x200 || second == 0xdb8)) && !(first == 0x3fff && second < 0x1000)
}
