package com.flops23.assistae.ui

import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.VideoCall
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.flops23.assistae.AppAction
import com.flops23.assistae.AppState
import com.flops23.assistae.RoomState

@Composable
internal fun RoomPanels(
    panel: RoomPanel?,
    room: RoomState,
    state: AppState,
    action: (AppAction) -> Unit,
    setPanel: (RoomPanel?) -> Unit
) {
    val dismiss = { setPanel(null) }
    val canChange = !state.busy && !room.reconnecting
    when (panel) {
        RoomPanel.QUEUE -> QueuePanel(room, canChange, action, dismiss) { setPanel(RoomPanel.ADD_VIDEO) }
        RoomPanel.ADD_VIDEO -> AddVideoPanel(room, state, action) { setPanel(RoomPanel.QUEUE) }
        RoomPanel.PARTICIPANTS -> ParticipantsPanel(room, canChange, action, dismiss) {
            setPanel(RoomPanel.SHARE)
            action(if (room.code == null) AppAction.LoadRoomCode else AppAction.RefreshFriends)
        }
        RoomPanel.SHARE -> SharePanel(room, state, action, dismiss)
        RoomPanel.LEAVE -> LeavePanel(room, !state.busy, action, dismiss)
        RoomPanel.CLOSE -> if (room.isAdmin) {
            Confirm(
                "Encerrar sala?",
                "Todos os participantes sairão da sala.",
                "Encerrar sala",
                dismiss,
                enabled = canChange
            ) {
                dismiss()
                if (canChange) action(AppAction.CloseRoom)
            }
        }
        null -> Unit
    }
}

@Composable
private fun QueuePanel(
    room: RoomState,
    canChange: Boolean,
    action: (AppAction) -> Unit,
    dismiss: () -> Unit,
    addVideo: () -> Unit
) {
    var removeId by rememberSaveable(room.id) { mutableStateOf<String?>(null) }
    AppSheet("Fila", dismiss) {
        Text("Vídeo atual", fontWeight = FontWeight.Bold)
        PanelRow {
            Text(
                room.playback.title
                    ?: if (room.playback.status == "empty") "Nenhum vídeo em reprodução" else "Vídeo da sala",
                color = Subtle
            )
        }
        Text("Próximos vídeos", fontWeight = FontWeight.Bold)
        if (room.queue.isEmpty()) EmptyCard("Fila vazia")
        val queueIds = room.queue.map { it.id }
        room.queue.forEachIndexed { index, item ->
            PanelRow {
                Column(Modifier.weight(1f)) {
                    Text(item.title, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    if (room.canControl) {
                        Row {
                            IconButton(
                                onClick = { action(AppAction.ReorderQueue(moveQueueItem(queueIds, index, -1))) },
                                enabled = canChange && index > 0
                            ) { Icon(Icons.Filled.ArrowUpward, "Mover para cima") }
                            IconButton(
                                onClick = { action(AppAction.ReorderQueue(moveQueueItem(queueIds, index, 1))) },
                                enabled = canChange && index < queueIds.lastIndex
                            ) { Icon(Icons.Filled.ArrowDownward, "Mover para baixo") }
                            IconButton(onClick = { removeId = item.id }, enabled = canChange) {
                                Icon(Icons.Filled.Delete, "Remover da fila")
                            }
                        }
                    }
                }
            }
        }
        if (room.canControl) {
            ActionButton(
                "Adicionar vídeo", addVideo, Modifier.fillMaxWidth(), canChange,
                leading = { Icon(Icons.Filled.VideoCall, null) }
            )
        }
    }
    room.queue.firstOrNull { it.id == removeId }?.let { item ->
        Confirm(
            "Remover da fila?", item.title, "Remover",
            dismiss = { removeId = null }, enabled = canChange && room.canControl
        ) {
            removeId = null
            if (canChange && room.canControl) action(AppAction.RemoveQueue(item.id))
        }
    }
}

private fun moveQueueItem(ids: List<String>, index: Int, step: Int): List<String> =
    ids.toMutableList().apply { add(index + step, removeAt(index)) }

@Composable
private fun AddVideoPanel(room: RoomState, state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var url by rememberSaveable(room.id) { mutableStateOf("") }
    var submitting by rememberSaveable(room.id) { mutableStateOf(false) }
    var sawBusy by rememberSaveable(room.id) { mutableStateOf(false) }
    LaunchedEffect(state.busy, submitting) {
        if (!submitting) return@LaunchedEffect
        if (state.busy) {
            sawBusy = true
        } else if (sawBusy) {
            submitting = false
            sawBusy = false
            if (state.error == null) back()
        }
    }
    val source = Uri.parse(url.trim())
    val enabled = room.canControl && !room.reconnecting && !state.busy &&
        source.scheme?.lowercase() in listOf("http", "https") && !source.host.isNullOrBlank()
    val add: (Boolean) -> Unit = { now ->
        submitting = true
        action(AppAction.AddVideo(url.trim(), now))
    }
    AppSheet("Adicionar vídeo", back) {
        AppField(url, { url = it }, "URL do vídeo", Modifier.fillMaxWidth())
        Text("Use um endereço direto de vídeo MP4 ou HLS gravado.", color = Subtle)
        if (state.busy && submitting) {
            Text("Verificando o vídeo…", color = Subtle)
            LinearProgressIndicator(Modifier.fillMaxWidth())
        }
        ActionButton("Reproduzir agora", { add(true) }, Modifier.fillMaxWidth(), enabled)
        ActionButton("Adicionar à fila", { add(false) }, Modifier.fillMaxWidth(), enabled && room.queue.size < 50)
        TextButton(onClick = back) { Text("Voltar à fila") }
    }
}

@Composable
private fun ParticipantsPanel(
    room: RoomState,
    canChange: Boolean,
    action: (AppAction) -> Unit,
    dismiss: () -> Unit,
    invite: () -> Unit
) {
    var transferId by rememberSaveable(room.id) { mutableStateOf<String?>(null) }
    var kickId by rememberSaveable(room.id) { mutableStateOf<String?>(null) }
    AppSheet("Participantes (${room.connected})", dismiss) {
        room.participants.filter { it.connected }.forEach { person ->
            PanelRow {
                Avatar(person.nickname)
                Column(Modifier.weight(1f)) {
                    Text(
                        if (person.isSelf) "${person.nickname} (você)" else person.nickname,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        if (person.isAdmin) "Administrador" else if (person.canControl) "Pode controlar" else "Participante",
                        color = Subtle,
                        style = MaterialTheme.typography.bodySmall
                    )
                    if (room.isAdmin && !person.isSelf) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Permitir controle", Modifier.weight(1f))
                            Switch(
                                checked = person.canControl,
                                onCheckedChange = { action(AppAction.SetControl(person.id, it)) },
                                enabled = canChange
                            )
                        }
                        TextButton(onClick = { transferId = person.id }, enabled = canChange) { Text("Transferir administração") }
                        TextButton(onClick = { kickId = person.id }, enabled = canChange) { Text("Expulsar") }
                    }
                }
            }
        }
        ActionButton(
            "Convidar amigos", invite, Modifier.fillMaxWidth(), canChange,
            leading = { Icon(Icons.Filled.PersonAdd, null) }
        )
    }
    room.participants.firstOrNull { it.id == transferId }?.let { person ->
        Confirm(
            "Transferir administração?",
            "${person.nickname} passará a administrar a sala. Você continuará como participante.",
            "Transferir",
            dismiss = { transferId = null },
            enabled = canChange && room.isAdmin && person.connected
        ) {
            transferId = null
            if (canChange && room.isAdmin) action(AppAction.TransferAdmin(person.id))
        }
    }
    room.participants.firstOrNull { it.id == kickId }?.let { person ->
        Confirm(
            "Expulsar ${person.nickname}?",
            "O participante sairá e ficará bloqueado nesta sala até ela ser encerrada.",
            "Expulsar",
            dismiss = { kickId = null },
            enabled = canChange && room.isAdmin
        ) {
            kickId = null
            if (canChange && room.isAdmin) action(AppAction.KickMember(person.id, true))
        }
    }
}

@Composable
private fun SharePanel(room: RoomState, state: AppState, action: (AppAction) -> Unit, dismiss: () -> Unit) {
    val context = LocalContext.current
    AppSheet("Compartilhar", dismiss) {
        Text("Código da sala", fontWeight = FontWeight.Bold)
        val code = room.code
        PanelRow {
            Text(code ?: if (state.busy) "Carregando…" else "Código indisponível", Modifier.weight(1f))
            if (code != null) {
                TextButton(onClick = { copyToClipboard(context, "Código da sala", code) }) { Text("Copiar") }
            }
        }
        if (code != null) {
            ActionButton("Compartilhar código", { shareCode(context, code) }, Modifier.fillMaxWidth())
        } else if (!state.busy) {
            TextButton(onClick = { action(AppAction.LoadRoomCode) }) { Text("Carregar código") }
        }
        Text("Convidar amigos", fontWeight = FontWeight.Bold)
        if (state.friends.isEmpty()) EmptyCard("Você ainda não tem amigos")
        state.friends.forEach { friend ->
            PanelRow {
                Avatar(friend.nickname)
                Text(friend.nickname, Modifier.weight(1f), fontWeight = FontWeight.Bold)
                TextButton(
                    onClick = { action(AppAction.InviteFriend(friend.id)) },
                    enabled = !state.busy && !room.reconnecting
                ) { Text("Convidar") }
            }
        }
    }
}

@Composable
private fun LeavePanel(room: RoomState, canChange: Boolean, action: (AppAction) -> Unit, dismiss: () -> Unit) {
    val candidates = if (room.isAdmin && !room.reconnecting) {
        room.participants.filter { it.connected && !it.isSelf }
    } else emptyList()
    if (candidates.isEmpty()) {
        Confirm("Sair da sala?", "Você voltará à tela inicial.", "Sair", dismiss, enabled = canChange) {
            dismiss()
            if (canChange) action(AppAction.LeaveRoom())
        }
    } else {
        AppSheet("Sair da sala?", dismiss) {
            Text("Você pode escolher quem vai administrar a sala.")
            candidates.forEach { candidate ->
                PanelRow(onClick = if (canChange) {
                    { dismiss(); action(AppAction.LeaveRoom(candidate.id)) }
                } else null) {
                    Avatar(candidate.nickname)
                    Text(candidate.nickname, fontWeight = FontWeight.Bold)
                }
            }
            ActionButton(
                "Sair sem escolher",
                { dismiss(); action(AppAction.LeaveRoom()) },
                Modifier.fillMaxWidth(),
                canChange
            )
            TextButton(onClick = dismiss) { Text("Cancelar") }
        }
    }
}
