package com.flops23.assistae

import android.app.Application
import android.os.SystemClock
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.conflate
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.time.Instant
import java.util.UUID

internal data class PlayerTarget(
    val mediaId: String,
    val epoch: Long,
    val url: String,
    val kind: String?,
    val status: String,
    val positionMs: Long,
)

private data class Admission(val roomId: String, val memberId: String, val generation: Long, val window: String?, val startSeq: Long) {
    fun params(media: Boolean = false) = if (media) {
        json("p_room" to roomId, "p_member" to memberId, "p_generation" to generation)
    } else {
        json("room_id" to roomId, "membership_id" to memberId, "generation" to generation)
    }

    companion object {
        fun from(data: JSONObject): Admission? {
            val room = data.text("room_id") ?: return null
            val member = data.text("membership_id") ?: return null
            return Admission(room, member, data.optLong("generation", 1), data.text("chat_window_id"), data.optLong("chat_start_after_seq"))
        }
    }
}

class AssistAeViewModel(application: Application) : AndroidViewModel(application) {
    private val api = (application as AssistAeApplication).backend
    private val mutable = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = mutable.asStateFlow()
    private val target = MutableStateFlow<PlayerTarget?>(null)
    internal val playback = target.asStateFlow()
    private var admission: Admission? = null
    private var revisions = JSONObject()
    private var profileRevisions = JSONObject()
    private var chatSeq = 0L
    private var heartbeatSeq = 0L
    private var lastBeat = 0L
    private var lostConnection = false
    private var foreground = true
    private var locallyStopped = false
    private var contextId: String? = null
    private var contextUntil = 0L
    private var actionJob: Job? = null
    private var searchJob: Job? = null
    private var realtimeJob: Job? = null
    private val refreshMutex = Mutex()
    private val contextMutex = Mutex()
    private var validRoom: RoomState? = null

    init {
        perform { bootstrap() }
        viewModelScope.launch {
            while (true) {
                delay(if (lostConnection) 2_000 else 5_000)
                if (shouldMaintainRoom()) refreshSafely()
            }
        }
    }

    fun onForeground(visible: Boolean) {
        foreground = visible
        if (visible) {
            locallyStopped = false
            viewModelScope.launch { refreshSafely() }
        }
    }

    fun onExternalStop() {
        locallyStopped = true
        target.value = null
    }

    fun onPlayerError() {
        if (admission != null) mutable.value = mutable.value.copy(error = "Não foi possível reproduzir este vídeo neste aparelho.")
    }

    fun onAction(action: AppAction) {
        when (action) {
            AppAction.DismissError -> mutable.value = mutable.value.copy(error = null)
            is AppAction.SearchRooms -> {
                searchJob?.cancel()
                searchJob = viewModelScope.launch {
                    delay(280)
                    try { loadPublicRooms(action.query) }
                    catch (cancel: CancellationException) { throw cancel }
                    catch (error: Exception) { showError(error) }
                }
            }
            else -> perform { dispatch(action) }
        }
    }

    private fun perform(block: suspend () -> Unit) {
        if (actionJob?.isActive == true) return
        actionJob = viewModelScope.launch {
            mutable.value = mutable.value.copy(busy = true, error = null)
            try {
                block()
            } catch (cancel: CancellationException) {
                throw cancel
            } catch (error: Exception) {
                showError(error)
                if (error is ApiFailure && error.code == "CONFLICT") {
                    refreshSafely()
                    try { applyProfile(api.rpc("get_my_profile")) } catch (_: ApiFailure) {}
                }
            } finally {
                mutable.value = mutable.value.copy(busy = false)
            }
        }
    }

    private suspend fun bootstrap() {
        val session = api.session()
        mutable.value = mutable.value.copy(betaId = session.userId)
        try {
            applyProfile(api.rpc("get_my_profile"))
        } catch (error: ApiFailure) {
            if (error.code == "NOT_FOUND_OR_UNAVAILABLE") {
                mutable.value = mutable.value.copy(betaId = null)
                return
            }
            if (error.code == "FORBIDDEN") throw ApiFailure("BETA_ACCESS_REQUIRED")
            throw error
        }
        homeOrResume()
    }

    private suspend fun homeOrResume() {
        startRealtime()
        val current = api.rpc("get_my_participation").data()
        val active = Admission.from(current)
        if (active == null) {
            mutable.value = mutable.value.copy(screen = Screen.HOME)
            loadPublicRooms(null)
        } else {
            admit(active)
            lostConnection = true
            refreshSafely()
        }
    }

    private fun startRealtime() {
        if (realtimeJob?.isActive == true) return
        realtimeJob = viewModelScope.launch {
            var backoff = 1_000L
            while (true) {
                try {
                    api.invalidations(api.session()).conflate().collect {
                        backoff = 1_000
                        if (shouldMaintainRoom()) refreshSafely()
                        if (foreground && mutable.value.screen in setOf(Screen.JOIN, Screen.FRIENDS)) loadSocial()
                    }
                } catch (cancel: CancellationException) {
                    throw cancel
                } catch (_: Exception) {
                    // The same authorized reads are also refreshed by the room heartbeat.
                }
                delay(backoff)
                backoff = (backoff * 2).coerceAtMost(15_000)
            }
        }
    }

    private suspend fun dispatch(action: AppAction) {
        when (action) {
            AppAction.Retry -> if (admission == null) bootstrap() else refreshSafely()
            is AppAction.EnsureProfile -> {
                applyProfile(api.rpc("ensure_profile", json("nickname" to action.nickname.trim())))
                homeOrResume()
            }
            is AppAction.Navigate -> {
                mutable.value = mutable.value.copy(screen = action.screen)
                when (action.screen) {
                    Screen.HOME, Screen.PUBLIC_ROOMS -> loadPublicRooms(null)
                    Screen.JOIN, Screen.FRIENDS -> loadSocial()
                    Screen.SETTINGS -> applyProfile(api.rpc("get_my_profile"))
                    else -> Unit
                }
            }
            is AppAction.CreateRoom -> enter("create_room", json("name" to action.name.trim(), "is_public" to action.isPublic))
            is AppAction.JoinCode -> join("code", action.code.trim())
            is AppAction.JoinPublic -> join("public_room_id", action.id)
            is AppAction.JoinInvite -> join("invite_id", action.id)
            AppAction.LoadRoomCode -> {
                val live = requireAdmission()
                val code = api.rpc("get_room_code", live.params()).data().text("code")
                if (admission == live) {
                    validRoom = validRoom?.copy(code = code)
                    mutable.value = mutable.value.copy(room = validRoom)
                }
                loadSocial()
            }
            is AppAction.SendMessage -> {
                val live = requireAdmission()
                mutate("send_message", live.params().put("chat_window_id", live.window)
                    .put("p_body", action.body.trim()).put("client_message_id", uuid()))
                refreshSafely()
            }
            is AppAction.LeaveRoom -> {
                val params = (admission ?: throw ApiFailure("RECONNECT_REQUIRED")).params()
                    .put("successor_membership_id", action.successorId ?: JSONObject.NULL)
                    .put("expected_room_revision", if (action.successorId == null) JSONObject.NULL else revision("room_revision"))
                mutate("leave_room", params)
                exitRoom()
                loadPublicRooms(null)
            }
            AppAction.CloseRoom -> {
                mutate("close_room", requireAdmission().params().put("expected_room_revision", revision("room_revision")))
                exitRoom()
                loadPublicRooms(null)
            }
            AppAction.PlayPause -> changePlayback()
            is AppAction.SeekBy -> setPlayback("seek", (target.value?.positionMs.orZero() + action.deltaMs).coerceAtLeast(0))
            AppAction.Advance -> roomMutation("advance_after_unverified_end", playbackParams().put("expected_queue_revision", revision("queue_revision")))
            is AppAction.AddVideo -> addVideo(action.url.trim(), action.now)
            is AppAction.ReorderQueue -> roomMutation("reorder_queue", queueParams().put("ordered_item_ids", JSONArray(action.ids)))
            is AppAction.RemoveQueue -> roomMutation("remove_queue_item", queueParams().put("item_id", action.id))
            is AppAction.ChangeNickname -> {
                mutate("change_nickname", json("nickname" to action.nickname.trim(), "expected_profile_revision" to profileRevisions.optLong("profile_revision")))
                applyProfile(api.rpc("get_my_profile"))
            }
            is AppAction.SetNotification -> {
                mutate("set_notification_preference", json("kind" to action.kind, "enabled" to action.enabled,
                    "expected_preferences_revision" to profileRevisions.optLong("preferences_revision")))
                applyProfile(api.rpc("get_my_profile"))
            }
            is AppAction.SaveMessagePreferences -> {
                mutate("save_message_preferences", json("p_position" to action.position, "size_key" to action.size,
                    "speed_key" to action.speed, "expected_preferences_revision" to profileRevisions.optLong("preferences_revision")))
                applyProfile(api.rpc("get_my_profile"))
            }
            AppAction.RefreshFriends -> loadSocial()
            is AppAction.RequestFriend -> socialMutation("request_friendship", json("user_code" to action.code.trim()))
            is AppAction.AnswerFriend -> socialMutation("answer_friend_request", json("friend_request_id" to action.id, "answer" to if (action.accept) "accept" else "reject"))
            is AppAction.CancelFriend -> socialMutation("cancel_friend_request", json("friend_request_id" to action.id))
            is AppAction.RemoveFriend -> socialMutation("remove_friend", json("friend_user_id" to action.id))
            is AppAction.InviteFriend -> socialMutation("invite_friend", requireAdmission().params().put("friend_user_id", action.id))
            is AppAction.SetControl -> manage("set_control_permission", action.id, "allowed" to action.enabled)
            is AppAction.TransferAdmin -> manage("transfer_admin", action.id)
            is AppAction.KickMember -> manage("kick_member", action.id)
            AppAction.DismissError, is AppAction.SearchRooms -> Unit
        }
    }

    private suspend fun loadPublicRooms(query: String?) {
        val limit = if (mutable.value.screen == Screen.HOME) 3 else 50
        val rooms = api.rpc("list_public_rooms", json("query" to query?.trim()?.takeIf(String::isNotEmpty), "limit_" to limit))
            .data().objects("rooms").map { PublicRoom(it.getString("id"), it.getString("name"), it.optInt("connected_count")) }
        mutable.value = mutable.value.copy(publicRooms = rooms)
    }

    private fun applyProfile(reply: JSONObject) {
        profileRevisions = reply.revisions()
        val profile = reply.data()
        val prefs = profile.optJSONObject("preferences") ?: JSONObject()
        mutable.value = mutable.value.copy(
            nickname = profile.optString("nickname"),
            friendCode = profile.optString("public_code"),
            notifyInvites = prefs.optBoolean("notify_invites", true),
            notifyFriendships = prefs.optBoolean("notify_friendships", true),
            messagePosition = prefs.optString("overlay_position", "bottom"),
            messageSize = prefs.optString("overlay_size_key", "small"),
            messageSpeed = prefs.optString("overlay_speed_key", "normal"),
            betaId = null,
        )
    }

    private suspend fun loadSocial() {
        val friends = api.rpc("list_friends", json("limit_" to 50)).data().objects("friends")
            .map { Friend(it.getString("user_id"), it.getString("nickname")) }
        val requests = listOf("incoming", "outgoing").flatMap { direction ->
            api.rpc("list_friend_requests", json("direction" to direction, "limit_" to 50)).data().objects("requests")
                .filter { it.optString("status") == "pending" }
                .map { FriendRequest(it.getString("id"), it.getString("nickname"), direction == "incoming") }
        }
        val invites = api.rpc("list_invites", json("limit_" to 50)).data().objects("invites")
            .map { Invite(it.getString("id"), it.getString("sender_nickname"), it.getString("room_name")) }
        mutable.value = mutable.value.copy(friends = friends, requests = requests, invites = invites)
    }

    private suspend fun socialMutation(name: String, params: JSONObject) {
        mutate(name, params)
        loadSocial()
    }

    private suspend fun context(force: Boolean): String = contextMutex.withLock {
        val cached = contextId
        if (cached != null && !force && SystemClock.elapsedRealtime() < contextUntil) return@withLock cached
        api.rpc("get_command_context").data().getString("command_context_id").also {
            contextId = it
            contextUntil = SystemClock.elapsedRealtime() + 14 * 60_000
        }
    }

    private suspend fun mutate(name: String, args: JSONObject): JSONObject {
        val requestId = uuid()
        args.put("request_id", requestId).put("command_context_id", context(false))
        return try {
            try {
                api.rpc(name, args)
            } catch (_: IOException) {
                delay(350)
                api.rpc(name, args)
            }
        } catch (failure: ApiFailure) {
            if (failure.code != "REQUEST_EXPIRED") throw failure
            api.rpc(name, args.put("command_context_id", context(true)))
        }
    }

    private suspend fun join(kind: String, value: String) = enter("join_room", json("target" to json(kind to value)))

    private suspend fun enter(name: String, args: JSONObject) {
        val reply = mutate(name, args)
        val active = Admission.from(reply.data())
        if (active == null) {
            homeOrResume()
            return
        }
        admit(active)
        refreshSafely()
    }

    private fun admit(active: Admission) {
        if (admission?.roomId != active.roomId) {
            validRoom = null
            target.value = null
            mutable.value = mutable.value.copy(messages = emptyList(), room = null)
        }
        admission = active
        chatSeq = active.startSeq
        heartbeatSeq = 0
        lastBeat = 0
        lostConnection = false
        locallyStopped = false
        mutable.value = mutable.value.copy(screen = Screen.ROOM)
    }

    private fun exitRoom(error: String? = null) {
        admission = null
        target.value = null
        validRoom = null
        lostConnection = false
        mutable.value = mutable.value.copy(room = null, messages = emptyList(), screen = Screen.HOME, error = error)
    }

    private fun shouldMaintainRoom() = admission != null &&
        (foreground || (!locallyStopped && (target.value?.status == "playing" || lostConnection && validRoom?.playback?.status == "playing")))

    private suspend fun refreshSafely() = refreshMutex.withLock {
        var active = admission ?: return@withLock
        try {
            if (lostConnection) {
                val recovered = mutate("reconnect_room", json("room_id" to active.roomId,
                    "membership_id" to active.memberId, "expected_generation" to active.generation))
                if (admission != active) return@withLock
                active = Admission.from(recovered.data()) ?: throw ApiFailure("RECONNECT_REQUIRED")
                admit(active)
            }
            if (lastBeat == 0L || SystemClock.elapsedRealtime() - lastBeat >= 9_500) {
                api.rpc("heartbeat", active.params().put("heartbeat_seq", ++heartbeatSeq))
                lastBeat = SystemClock.elapsedRealtime()
            }
            val snapshot = api.rpc("get_room_snapshot", active.params())
            if (admission != active) return@withLock
            val window = Admission.from(snapshot.data().optJSONObject("admission") ?: JSONObject())
            if (window != null && window.window != active.window) {
                admission = window
                active = window
                chatSeq = window.startSeq
            }
            applySnapshot(active, snapshot)
            if (foreground && active.window != null) loadMessages(active)
        } catch (cancel: CancellationException) {
            throw cancel
        } catch (_: IOException) {
            if (admission == active) markDisconnected()
        } catch (failure: ApiFailure) {
            if (admission != active) return@withLock
            when (failure.code) {
                "RECONNECT_REQUIRED" -> markDisconnected()
                "STALE_CONNECTION" -> {
                    val current = Admission.from(api.rpc("get_my_participation").data())
                    if (current == null) exitRoom("A participação na sala terminou.")
                    else { admit(current); markDisconnected() }
                }
                "CLOSED", "REJOIN_REQUIRED", "NOT_FOUND_OR_UNAVAILABLE", "FORBIDDEN", "BETA_ACCESS_REQUIRED", "BETA_REQUIRED" ->
                    exitRoom(messageFor(failure.code))
                else -> showError(failure)
            }
        }
    }

    private fun markDisconnected() {
        lostConnection = true
        target.value = null
        mutable.value = mutable.value.copy(room = validRoom?.copy(reconnecting = true, code = null))
    }

    private fun applySnapshot(active: Admission, reply: JSONObject) {
        revisions = reply.revisions()
        val room = reply.data()
        val pb = room.optJSONObject("playback") ?: JSONObject()
        val admin = room.text("admin_membership_id")
        val people = room.objects("participants").map {
            val id = it.getString("membership_id")
            Participant(id, it.getString("nickname"), id == admin, it.optBoolean("can_control"), id == active.memberId,
                it.optString("state") == "active")
        }
        val status = pb.optString("status", "empty")
        val duration = pb.text("duration_ms")?.toLongOrNull()
        val elapsed = if (status == "playing") {
            val server = instantMs(reply.text("server_time"))
            val start = instantMs(pb.text("reference_at"))
            if (server != null && start != null) (server - start).coerceAtLeast(0) else 0L
        } else 0L
        val position = (pb.optLong("position_ms") + elapsed).coerceAtMost(duration ?: Long.MAX_VALUE)
        val mediaUrl = pb.text("source_url")
        val mediaId = pb.text("media_id")
        val queue = room.objects("queue").map {
            QueueItem(it.getString("id"), it.text("title") ?: safeMediaTitle(it.text("source_url")))
        }
        validRoom = RoomState(
            active.roomId, room.optString("name"), validRoom?.takeIf { it.id == active.roomId }?.code,
            room.optInt("connected_count"), admin == active.memberId || people.any { it.isSelf && it.canControl },
            admin == active.memberId, false,
            PlaybackState(status, duration, position, pb.text("termination_mode"), mediaUrl?.let(::safeMediaTitle)), queue, people,
        )
        mutable.value = mutable.value.copy(room = validRoom)
        target.value = if (!locallyStopped && mediaUrl != null && mediaId != null) {
            PlayerTarget(mediaId, pb.optLong("media_epoch"), mediaUrl, pb.text("kind"), status, position)
        } else null
        roomEpoch = pb.optLong("media_epoch")
    }

    private var roomEpoch = 0L

    private suspend fun loadMessages(active: Admission) {
        repeat(6) {
            val messages = api.rpc("list_messages", active.params().put("chat_window_id", active.window)
                .put("after_seq", chatSeq).put("limit_", 50)).data().objects("messages")
            if (admission != active || lostConnection || messages.isEmpty()) return
            chatSeq = messages.last().optLong("seq", chatSeq)
            val additions = messages.map { ChatMessage(it.getString("seq"), it.getString("sender_nickname"), it.getString("body")) }
            mutable.value = mutable.value.copy(messages = mutable.value.messages + additions)
            if (messages.size < 50) return
        }
    }

    private suspend fun roomMutation(name: String, params: JSONObject) {
        mutate(name, params)
        refreshSafely()
    }

    private fun requireAdmission(): Admission = admission?.takeUnless { lostConnection }
        ?: throw ApiFailure("RECONNECT_REQUIRED")

    private fun revision(key: String) = revisions.optLong(key)
    private fun queueParams() = requireAdmission().params(true).put("expected_queue_revision", revision("queue_revision"))
    private fun playbackParams() = requireAdmission().params(true)
        .put("expected_playback_revision", revision("playback_revision")).put("expected_media_epoch", roomEpoch)

    private suspend fun changePlayback() {
        val status = validRoom?.playback?.status ?: "empty"
        if (status == "empty") {
            roomMutation("start_queue", queueParams().put("expected_playback_revision", revision("playback_revision")))
        } else {
            setPlayback(if (status == "playing") "pause" else "play", null)
        }
    }

    private suspend fun setPlayback(action: String, position: Long?) {
        roomMutation("set_playback", playbackParams().put("action", action).put("position_ms", position ?: JSONObject.NULL))
    }

    private suspend fun addVideo(url: String, now: Boolean) {
        val live = requireAdmission()
        val creation = mutate("validate_media", live.params(true).put("source_url", url)).data()
        val id = creation.getString("validation_id")
        api.runValidation(id, creation.getString("execution_token"))
        repeat(18) {
            val evaluation = api.rpc("get_media_validation", live.params(true).put("validation_id", id)).data()
            when (evaluation.optString("status")) {
                "valid", "inconclusive" -> {
                    if (admission != live || lostConnection) throw ApiFailure("RECONNECT_REQUIRED")
                    val params = (if (now) playbackParams() else queueParams())
                        .put("source_url", url).put("validation_reference", evaluation.getString("validation_reference"))
                    roomMutation(if (now) "play_now" else "add_to_queue", params)
                    return
                }
                "invalid", "expired" -> throw ApiFailure("SOURCE_UNAVAILABLE")
                else -> delay(850)
            }
        }
        throw ApiFailure("TEMPORARILY_UNAVAILABLE")
    }

    private suspend fun manage(name: String, id: String, vararg extras: Pair<String, Any>) {
        val params = requireAdmission().params().put("target_membership_id", id)
            .put("expected_room_revision", revision("room_revision"))
        extras.forEach { (key, value) -> params.put(key, value) }
        roomMutation(name, params)
    }

    private fun showError(error: Exception) {
        val message = if (error is ApiFailure) messageFor(error.code) else "Falha de conexão. Tente novamente."
        mutable.value = mutable.value.copy(error = message)
    }
}

private fun safeMediaTitle(url: String?): String = try {
    android.net.Uri.parse(url ?: "").lastPathSegment?.take(100)?.takeIf(String::isNotBlank) ?: "Vídeo"
} catch (_: Exception) {
    "Vídeo"
}

private fun uuid() = UUID.randomUUID().toString()
private fun Long?.orZero() = this ?: 0L
private fun instantMs(value: String?) = value?.let { runCatching { Instant.parse(it).toEpochMilli() }.getOrNull() }

private fun messageFor(code: String): String = when (code) {
    "APP_CONFIGURATION_MISSING" -> "Este APK precisa da configuração do Supabase."
    "anonymous_provider_disabled" -> "O acesso sem login ainda precisa ser ativado no assistAe."
    "SESSION_UNAVAILABLE", "refresh_token_not_found" -> "Não foi possível recuperar a identidade deste aparelho."
    "BETA_ACCESS_REQUIRED", "BETA_REQUIRED" -> "Seu aparelho ainda precisa ser liberado para o teste fechado."
    "NOT_FOUND_OR_UNAVAILABLE" -> "O código, a sala ou o convite não está disponível."
    "CLOSED" -> "Esta sala foi encerrada."
    "ROOM_FULL" -> "A sala está lotada."
    "ALREADY_IN_ROOM" -> "Você já está em uma sala."
    "REJOIN_REQUIRED" -> "Sua vaga expirou. Entre na sala novamente."
    "RECONNECT_REQUIRED", "STALE_CONNECTION" -> "Reconectando à sala…"
    "FORBIDDEN" -> "Você não tem permissão para essa ação."
    "SOURCE_UNAVAILABLE" -> "Vídeo indisponível. Use um link direto de MP4 ou HLS gravado."
    "CONFLICT" -> "A sala mudou. Confira o estado atual e tente novamente."
    "QUEUE_FULL" -> "A fila já tem 50 vídeos."
    "RATE_LIMITED" -> "Aguarde um pouco antes de tentar novamente."
    "INVALID_INPUT" -> "Confira os dados informados."
    else -> "Não foi possível concluir. Tente novamente."
}
