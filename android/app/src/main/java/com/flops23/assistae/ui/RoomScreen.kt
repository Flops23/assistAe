package com.flops23.assistae.ui

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.SystemClock
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.displayCutout
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.FullscreenExit
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.flops23.assistae.AppAction
import com.flops23.assistae.AppState
import com.flops23.assistae.ChatMessage
import com.flops23.assistae.RoomState
import java.util.Locale
import kotlinx.coroutines.delay

internal enum class RoomPanel { QUEUE, ADD_VIDEO, PARTICIPANTS, SHARE, LEAVE, CLOSE }

@Composable
internal fun RoomScreen(
    state: AppState,
    room: RoomState,
    action: (AppAction) -> Unit,
    playerContent: @Composable (Modifier) -> Unit
) {
    val landscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE
    val activity = LocalContext.current.findActivity()
    var panel by rememberSaveable(room.id) { mutableStateOf<RoomPanel?>(null) }
    var menu by rememberSaveable(room.id) { mutableStateOf(false) }
    var chatOpen by rememberSaveable(room.id) { mutableStateOf(false) }
    var draft by rememberSaveable(room.id) { mutableStateOf("") }
    var submittedDraft by rememberSaveable(room.id) { mutableStateOf<String?>(null) }
    var sending by rememberSaveable(room.id) { mutableStateOf(false) }
    var controlsVisible by rememberSaveable(room.id, landscape) { mutableStateOf(true) }
    val rotate = {
        chatOpen = false
        activity?.requestedOrientation = if (landscape) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        }
    }
    val back = {
        when {
            panel == RoomPanel.ADD_VIDEO -> panel = RoomPanel.QUEUE
            panel != null -> panel = null
            menu -> menu = false
            landscape && chatOpen -> chatOpen = false
            landscape -> rotate()
            else -> panel = RoomPanel.LEAVE
        }
    }
    BackHandler(onBack = back)
    DisposableEffect(activity, landscape) {
        val window = activity?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, it.decorView) }
        if (landscape) {
            controller?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller?.hide(WindowInsetsCompat.Type.systemBars())
        }
        onDispose { controller?.show(WindowInsetsCompat.Type.systemBars()) }
    }
    DisposableEffect(activity, room.id) {
        onDispose {
            if (activity != null && !activity.isChangingConfigurations) {
                activity.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
            }
        }
    }
    LaunchedEffect(landscape) {
        if (!landscape) chatOpen = false
    }
    LaunchedEffect(controlsVisible, room.playback.status, panel, menu, chatOpen) {
        if (controlsVisible && room.playback.status == "playing" && panel == null && !menu && !chatOpen) {
            delay(4_000)
            controlsVisible = false
        }
    }
    LaunchedEffect(state.busy, submittedDraft) {
        val submitted = submittedDraft ?: return@LaunchedEffect
        if (state.busy) {
            sending = true
        } else if (sending) {
            if (state.error == null && draft == submitted) draft = ""
            submittedDraft = null
            sending = false
        }
    }

    val send = {
        if (!state.busy && !room.reconnecting && draft.isNotBlank()) {
            submittedDraft = draft
            action(AppAction.SendMessage(draft.trim()))
        }
    }
    val openPanel: (RoomPanel) -> Unit = { selected ->
        panel = selected
        if (selected == RoomPanel.SHARE) {
            action(if (room.code == null) AppAction.LoadRoomCode else AppAction.RefreshFriends)
        }
    }
    val roomHeader: @Composable (Modifier) -> Unit = { modifier ->
        RoomHeader(room, menu, modifier, back, { menu = it }, openPanel)
    }
    val player: @Composable (Modifier) -> Unit = { modifier ->
        PlayerArea(
            room, controlsVisible, landscape, state.busy, modifier,
            toggleControls = { controlsVisible = !controlsVisible },
            rotate = rotate,
            openQueue = { openPanel(RoomPanel.QUEUE) },
            action = action,
            playerContent = playerContent
        )
    }
    val chat: @Composable (Modifier, Boolean) -> Unit = { modifier, closeable ->
        ChatPane(
            messages = state.messages,
            draft = draft,
            updateDraft = { if (it.characters() <= 500) draft = it },
            send = send,
            sendEnabled = !state.busy && !room.reconnecting && draft.isNotBlank(),
            close = if (closeable) ({ chatOpen = false }) else null,
            modifier = modifier
        )
    }

    BoxWithConstraints(
        Modifier.fillMaxSize().then(
            if (landscape) Modifier.windowInsetsPadding(WindowInsets.displayCutout)
            else Modifier.windowInsetsPadding(WindowInsets.safeDrawing)
        ).imePadding()
    ) {
        if (landscape) {
            player(Modifier.fillMaxSize())
            if (controlsVisible || menu) {
                roomHeader(Modifier.align(Alignment.TopCenter).zIndex(1f).background(Color.Black.copy(alpha = .58f)))
            }
            IconButton(
                onClick = { chatOpen = !chatOpen },
                modifier = Modifier.align(Alignment.TopEnd).zIndex(1f).padding(top = 58.dp, end = 12.dp)
                    .clip(CircleShape).background(Color.Black.copy(alpha = .64f))
            ) {
                Icon(Icons.AutoMirrored.Filled.Chat, if (chatOpen) "Fechar chat" else "Abrir chat")
            }
            if (chatOpen) {
                chat(
                    Modifier.align(Alignment.CenterEnd).zIndex(2f).fillMaxHeight().width(minOf(330.dp, maxWidth * .55f))
                        .background(Background.copy(alpha = .94f)),
                    true
                )
            }
        } else {
            val playerHeight = minOf(maxWidth * (9f / 16f), maxHeight * .49f)
            Column(Modifier.fillMaxSize()) {
                roomHeader(Modifier)
                player(Modifier.fillMaxWidth().height(playerHeight))
                chat(Modifier.fillMaxWidth().weight(1f), false)
            }
        }
        ChatOverlay(room.id, state, landscape, Modifier.fillMaxSize())
        if (room.reconnecting) {
            Column(
                Modifier.align(Alignment.TopCenter).zIndex(3f).padding(top = 60.dp).clip(CardShape).background(Surface)
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text("Reconectando…", color = TextLight)
                LinearProgressIndicator(Modifier.width(120.dp))
            }
        }
    }
    RoomPanels(panel, room, state, action) { panel = it }
}

private fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

@Composable
private fun RoomHeader(
    room: RoomState,
    menu: Boolean,
    modifier: Modifier,
    back: () -> Unit,
    setMenu: (Boolean) -> Unit,
    openPanel: (RoomPanel) -> Unit
) {
    Row(modifier.fillMaxWidth().heightIn(min = 52.dp), verticalAlignment = Alignment.CenterVertically) {
        IconButton(onClick = back) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar") }
        Text(
            room.name,
            Modifier.weight(1f),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        TextButton(onClick = { openPanel(RoomPanel.PARTICIPANTS) }) {
            Icon(Icons.Filled.Group, "Participantes conectados")
            Text(room.connected.toString(), Modifier.padding(start = 6.dp), fontWeight = FontWeight.Bold)
        }
        Box {
            IconButton(onClick = { setMenu(true) }) { Icon(Icons.Filled.MoreVert, "Menu da sala") }
            DropdownMenu(expanded = menu, onDismissRequest = { setMenu(false) }) {
                val options = buildList {
                    add("Fila" to RoomPanel.QUEUE)
                    add("Compartilhar" to RoomPanel.SHARE)
                    add("Sair da sala" to RoomPanel.LEAVE)
                    if (room.isAdmin) add("Encerrar sala" to RoomPanel.CLOSE)
                }
                options.forEach { (label, panel) ->
                    DropdownMenuItem(text = { Text(label) }, onClick = { setMenu(false); openPanel(panel) })
                }
            }
        }
    }
}

@Composable
private fun PlayerArea(
    room: RoomState,
    controlsVisible: Boolean,
    landscape: Boolean,
    busy: Boolean,
    modifier: Modifier,
    toggleControls: () -> Unit,
    rotate: () -> Unit,
    openQueue: () -> Unit,
    action: (AppAction) -> Unit,
    playerContent: @Composable (Modifier) -> Unit
) {
    val playback = room.playback
    val empty = playback.status == "empty"
    val ended = playback.status == "ended"
    val canControl = room.canControl && !room.reconnecting && !busy
    var seekPosition by remember { mutableStateOf<Float?>(null) }
    BoxWithConstraints(modifier.background(Color.Black).clipToBounds()) {
        val compact = maxHeight < 155.dp
        playerContent(Modifier.fillMaxSize())
        Box(
            Modifier.fillMaxSize().clickable(onClickLabel = if (controlsVisible) "Ocultar controles" else "Mostrar controles",
                role = Role.Button, onClick = toggleControls)
        )
        if (empty) {
            Column(
                Modifier.align(Alignment.Center).padding(horizontal = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (!compact) Icon(Icons.Filled.VideoLibrary, null, tint = Accent, modifier = Modifier.size(30.dp))
                Text(
                    if (room.queue.isEmpty()) "Adicione um vídeo" else "Vídeo pronto na fila",
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                if (room.queue.isNotEmpty() && canControl) {
                    IconButton(onClick = { action(AppAction.PlayPause) }) { Icon(Icons.Filled.PlayArrow, "Reproduzir") }
                } else if (!compact && room.canControl) {
                    Text("Abra a Fila no menu da sala", color = Subtle, textAlign = TextAlign.Center)
                }
            }
        } else {
            if (ended && room.queue.isEmpty()) {
                Column(
                    Modifier.align(Alignment.TopCenter).padding(top = if (landscape) 54.dp else 4.dp)
                        .clip(CardShape).background(Color.Black.copy(alpha = .65f)).padding(horizontal = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("Fila vazia", fontWeight = FontWeight.Bold)
                    TextButton(onClick = openQueue) { Text("Abrir fila") }
                }
            }
            if (controlsVisible && room.canControl) {
                Row(
                    Modifier.align(Alignment.Center).clip(CircleShape).background(Color.Black.copy(alpha = .52f)),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = { action(AppAction.SeekBy(-10_000)) }, enabled = canControl) {
                        Icon(Icons.Filled.Replay10, "Retroceder 10 segundos")
                    }
                    IconButton(onClick = { action(AppAction.PlayPause) }, enabled = canControl) {
                        if (playback.status == "playing") {
                            Icon(Icons.Filled.Pause, "Pausar", modifier = Modifier.size(34.dp))
                        } else {
                            Icon(Icons.Filled.PlayArrow, "Reproduzir", modifier = Modifier.size(34.dp))
                        }
                    }
                    IconButton(onClick = { action(AppAction.SeekBy(10_000)) }, enabled = canControl) {
                        Icon(Icons.Filled.Forward10, "Avançar 10 segundos")
                    }
                }
            }
        }
        if (controlsVisible || empty) {
            Row(
                Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                    .background(Color.Black.copy(alpha = if (empty) 0f else .65f)).padding(start = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (!empty) {
                    val duration = playback.durationMs?.takeIf { it > 0 }
                    val elapsed = seekPosition?.toLong() ?: playback.positionMs
                    Text(
                        duration?.let { "${clockText(elapsed)} / ${clockText(it)}" } ?: clockText(elapsed),
                        style = MaterialTheme.typography.labelMedium
                    )
                    if (duration != null && room.canControl) {
                        Slider(
                            value = elapsed.coerceIn(0L, duration).toFloat(),
                            valueRange = 0f..duration.toFloat(),
                            onValueChange = { seekPosition = it },
                            onValueChangeFinished = {
                                seekPosition?.let { action(AppAction.SeekBy(it.toLong() - playback.positionMs)) }
                                seekPosition = null
                            },
                            enabled = canControl,
                            modifier = Modifier.weight(1f)
                        )
                    } else if (duration != null) {
                        LinearProgressIndicator(
                            progress = { (elapsed.toFloat() / duration).coerceIn(0f, 1f) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                if (empty || playback.durationMs == null) Box(Modifier.weight(1f))
                if (playback.status == "playing" && playback.terminationMode == "authorized_manual" && room.canControl) {
                    TextButton(onClick = { action(AppAction.Advance) }, enabled = canControl) { Text("Finalizar vídeo") }
                }
                IconButton(onClick = rotate) {
                    Icon(
                        if (landscape) Icons.Filled.FullscreenExit else Icons.Filled.Fullscreen,
                        if (landscape) "Sair da tela cheia" else "Tela cheia"
                    )
                }
            }
        }
    }
}

private fun clockText(milliseconds: Long): String {
    val seconds = milliseconds.coerceAtLeast(0) / 1_000
    return if (seconds >= 3_600) {
        String.format(Locale.ROOT, "%d:%02d:%02d", seconds / 3_600, seconds / 60 % 60, seconds % 60)
    } else {
        String.format(Locale.ROOT, "%d:%02d", seconds / 60, seconds % 60)
    }
}

@Composable
private fun ChatPane(
    messages: List<ChatMessage>,
    draft: String,
    updateDraft: (String) -> Unit,
    send: () -> Unit,
    sendEnabled: Boolean,
    close: (() -> Unit)?,
    modifier: Modifier
) {
    val list = rememberLazyListState()
    LaunchedEffect(messages.lastOrNull()?.id) {
        if (messages.isNotEmpty()) list.scrollToItem(messages.lastIndex)
    }
    Column(modifier.padding(horizontal = 12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(Modifier.fillMaxWidth().heightIn(min = 44.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Chat", Modifier.weight(1f), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            if (close != null) {
                IconButton(onClick = close) { Icon(Icons.Filled.Close, "Fechar chat") }
            }
        }
        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            state = list,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(messages, key = { it.id }) { message ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Avatar(message.nickname)
                    Column(Modifier.clip(CardShape).background(Panel).padding(horizontal = 10.dp, vertical = 6.dp)) {
                        Text(message.nickname, fontWeight = FontWeight.Bold, color = TextLight)
                        Text(message.body, color = TextLight)
                    }
                }
            }
        }
        Row(
            Modifier.fillMaxWidth().padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AppField(draft, updateDraft, "Mensagem", Modifier.weight(1f), singleLine = false)
            IconButton(
                onClick = send,
                enabled = sendEnabled,
                modifier = Modifier.clip(CircleShape)
                    .then(if (sendEnabled) Modifier.background(PurpleGradient) else Modifier.background(Panel))
            ) {
                Icon(Icons.AutoMirrored.Filled.Send, "Enviar mensagem")
            }
        }
    }
}

@Composable
private fun ChatOverlay(roomId: String, state: AppState, landscape: Boolean, modifier: Modifier) {
    var lastSeen by rememberSaveable(roomId) { mutableStateOf<String?>(null) }
    var currentId by rememberSaveable(roomId) { mutableStateOf<String?>(null) }
    var pendingIds by rememberSaveable(roomId) { mutableStateOf(arrayListOf<String>()) }
    var pendingTimes by rememberSaveable(roomId) { mutableStateOf(longArrayOf()) }
    val motion = remember(roomId) { Animatable(0f) }
    val speed = messageOverlayDuration(state.messageSpeed)
    val fontSize = messageOverlayFontSize(state.messageSize)
    LaunchedEffect(state.messages.lastOrNull()?.id) {
        val newest = state.messages.lastOrNull() ?: return@LaunchedEffect
        val previous = state.messages.indexOfLast { it.id == lastSeen }
        val arrivals = if (previous >= 0) state.messages.drop(previous + 1) else listOf(newest)
        lastSeen = newest.id
        val time = SystemClock.elapsedRealtime()
        val pending = (pendingIds.zip(pendingTimes.toList()) + arrivals.map { it.id to time })
            .filter { time - it.second <= 20_000 }
            .takeLast(5)
        pendingIds = ArrayList(pending.map { it.first })
        pendingTimes = pending.map { it.second }.toLongArray()
    }
    val message = state.messages.find { it.id == currentId }
    LaunchedEffect(landscape, currentId, pendingIds, pendingTimes) {
        if (!landscape || currentId != null) return@LaunchedEffect
        val now = SystemClock.elapsedRealtime()
        val next = pendingIds.indices.firstOrNull { now - pendingTimes[it] <= 20_000 }
        currentId = next?.let { pendingIds[it] }
        pendingIds = ArrayList(pendingIds.drop((next ?: pendingIds.lastIndex) + 1))
        pendingTimes = pendingTimes.takeLast(pendingIds.size).toLongArray()
    }
    LaunchedEffect(landscape, currentId, message != null, speed) {
        if (!landscape || currentId == null) return@LaunchedEffect
        motion.snapTo(0f)
        if (message != null) motion.animateTo(1f, tween(speed, easing = LinearEasing))
        currentId = null
    }
    if (landscape && message != null) {
        BoxWithConstraints(modifier.clipToBounds()) {
            val width = minOf(maxWidth * .52f, 340.dp)
            val edge = if (state.messagePosition == "top") Alignment.TopStart else Alignment.BottomStart
            Text(
                "${message.nickname}: ${message.body}",
                modifier = Modifier.align(edge)
                    .offset(x = (maxWidth + width) * motion.value - width)
                    .padding(vertical = 26.dp).width(width)
                    .clip(CardShape).background(Color.Black.copy(alpha = .68f))
                    .border(1.dp, Outline, CardShape).padding(horizontal = 10.dp, vertical = 5.dp),
                fontSize = fontSize,
                lineHeight = fontSize * 1.2f,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

internal fun messageOverlayDuration(speed: String): Int = when (speed) {
    "slow" -> 10_000
    "fast" -> 5_000
    else -> 7_000
}

internal fun messageOverlayFontSize(size: String) = when (size) {
    "medium" -> 15.sp
    "large" -> 18.sp
    else -> 12.sp
}
