package com.flops23.assistae

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.os.Build
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.annotation.OptIn
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import androidx.media3.ui.PlayerView
import com.flops23.assistae.ui.AssistAeScreen
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.launch
import kotlin.math.abs

@OptIn(UnstableApi::class)
class MainActivity : ComponentActivity() {
    private val model by viewModels<AssistAeViewModel>()
    private lateinit var connection: ListenableFuture<MediaController>
    private var controller by mutableStateOf<MediaController?>(null)
    private var appliedMedia: Pair<String, Long>? = null
    private var pendingPushScreen by mutableStateOf<Screen?>(null)
    private val notifications = registerForActivityResult(ActivityResultContracts.RequestPermission()) { allowed ->
        if (allowed) (application as AssistAeApplication).registerPush()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        readPushDestination(intent)
        enableEdgeToEdge()
        val token = SessionToken(this, ComponentName(this, PlaybackService::class.java))
        connection = MediaController.Builder(this, token).buildAsync()
        connection.addListener({
            if (isDestroyed) return@addListener
            runCatching { connection.get() }.onSuccess { player ->
                controller = player
                player.addListener(object : Player.Listener {
                    override fun onPlayerError(error: PlaybackException) { model.onPlayerError() }
                })
                applyPlayback(model.playback.value)
            }
        }, ContextCompat.getMainExecutor(this))
        lifecycleScope.launch { model.playback.collect(::applyPlayback) }
        RoomMediaActions.stopLocally = model::onExternalStop
        RoomMediaActions.playPause = {
            model.state.value.room?.takeIf { it.canControl && !it.reconnecting }
                ?.let { model.onAction(AppAction.PlayPause) }
        }
        RoomMediaActions.seek = { delta ->
            model.state.value.room?.takeIf { it.canControl && !it.reconnecting }
                ?.let { model.onAction(AppAction.SeekBy(delta)) }
        }
        setContent {
            val state by model.state.collectAsState()
            LaunchedEffect(state.nickname, state.busy) {
                if (state.nickname.isNotBlank() && !state.busy) configurePush()
            }
            val destination = pendingPushScreen
            LaunchedEffect(destination, state.screen, state.busy) {
                if (destination != null && !state.busy && state.screen != Screen.PROFILE && state.room == null) {
                    pendingPushScreen = null
                    model.onAction(AppAction.Navigate(destination))
                }
            }
            AssistAeScreen(state, model::onAction) { modifier ->
                val player = controller
                AndroidView(
                    modifier = modifier,
                    factory = { context -> PlayerView(context).apply { useController = false } },
                    update = { it.player = player },
                    onRelease = { it.player = null },
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        model.onForeground(true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        readPushDestination(intent)
    }

    override fun onStop() {
        model.onForeground(false)
        super.onStop()
    }

    override fun onDestroy() {
        RoomMediaActions.playPause = null
        RoomMediaActions.seek = null
        RoomMediaActions.stopLocally = null
        MediaController.releaseFuture(connection)
        super.onDestroy()
    }

    private var registeredThisLaunch = false

    private fun configurePush() {
        val app = application as AssistAeApplication
        if (!app.pushAvailable || registeredThisLaunch) return
        registeredThisLaunch = true
        val prefs = getSharedPreferences("notifications", MODE_PRIVATE)
        if (Build.VERSION.SDK_INT >= 33 && !canNotify(this) && !prefs.getBoolean("asked", false)) {
            prefs.edit().putBoolean("asked", true).apply()
            notifications.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            app.registerPush()
        }
    }

    private fun readPushDestination(intent: Intent) {
        pendingPushScreen = when (intent.getStringExtra("kind")) {
            "friend_request" -> Screen.FRIENDS
            "room_invite" -> Screen.JOIN
            else -> null
        }
        intent.removeExtra("kind")
    }

    private fun applyPlayback(target: PlayerTarget?) {
        val player = controller ?: return
        if (target == null) {
            if (appliedMedia != null) {
                player.stop()
                player.clearMediaItems()
                appliedMedia = null
            }
            return
        }
        val media = target.mediaId to target.epoch
        if (appliedMedia != media) {
            val item = MediaItem.Builder().setMediaId(target.mediaId).setUri(target.url)
                .setMimeType(if (target.kind == "hls") MimeTypes.APPLICATION_M3U8 else MimeTypes.VIDEO_MP4)
                .setMediaMetadata(MediaMetadata.Builder().setTitle("assistAe").build())
                .build()
            player.setMediaItem(item, target.positionMs)
            player.prepare()
            appliedMedia = media
        } else if (abs(player.currentPosition - target.positionMs) > 1_500) {
            player.seekTo(target.positionMs)
        }
        player.playWhenReady = target.status == "playing"
    }
}
