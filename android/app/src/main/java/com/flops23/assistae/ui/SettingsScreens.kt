package com.flops23.assistae.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.flops23.assistae.AppAction
import com.flops23.assistae.AppState
import com.flops23.assistae.Screen
import kotlinx.coroutines.delay

private enum class SettingsPanel { NICKNAME, MESSAGES, NOTIFICATIONS, ABOUT }

@Composable
internal fun SettingsScreen(state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var panel by rememberSaveable { mutableStateOf<SettingsPanel?>(null) }
    val dismiss = { panel = null }
    StandardPage("Configurações", back) {
        SettingsRow("Mudar apelido", Icons.Filled.Edit) { panel = SettingsPanel.NICKNAME }
        SettingsRow("Configuração de mensagem", Icons.Filled.TextFields) { panel = SettingsPanel.MESSAGES }
        SettingsRow("Notificações", Icons.Filled.Notifications) { panel = SettingsPanel.NOTIFICATIONS }
        SettingsRow("Sobre o app", Icons.Filled.Info) { panel = SettingsPanel.ABOUT }
        SettingsRow("Amigos", Icons.Filled.Group) { action(AppAction.Navigate(Screen.FRIENDS)) }
    }
    when (panel) {
        SettingsPanel.NICKNAME -> {
            var nickname by rememberSaveable { mutableStateOf(state.nickname) }
            AppSheet("Mudar apelido", dismiss) {
                Avatar(nickname)
                AppField(nickname, { if (it.characters() <= 24) nickname = it }, "Apelido", Modifier.fillMaxWidth())
                ActionButton(
                    "Salvar",
                    { action(AppAction.ChangeNickname(nickname.trim())); dismiss() },
                    Modifier.fillMaxWidth(),
                    !state.busy && nickname.trim().characters() in 2..24
                )
                TextButton(onClick = dismiss) { Text("Cancelar") }
            }
        }
        SettingsPanel.MESSAGES -> {
            var position by rememberSaveable { mutableStateOf(state.messagePosition) }
            var size by rememberSaveable { mutableStateOf(state.messageSize) }
            var speed by rememberSaveable { mutableStateOf(state.messageSpeed) }
            AppSheet("Configuração de mensagem", dismiss) {
                PreferenceOptions("Posição", listOf("bottom" to "Embaixo", "top" to "Em cima"), position) { position = it }
                PreferenceOptions("Tamanho", listOf("small" to "Pequeno", "medium" to "Médio", "large" to "Grande"), size) { size = it }
                PreferenceOptions("Velocidade", listOf("slow" to "Lenta", "normal" to "Normal", "fast" to "Rápida"), speed) { speed = it }
                MessagePreview(position, size, speed)
                ActionButton(
                    "Salvar",
                    { action(AppAction.SaveMessagePreferences(position, size, speed)); dismiss() },
                    Modifier.fillMaxWidth(),
                    !state.busy
                )
                TextButton(onClick = dismiss) { Text("Cancelar") }
            }
        }
        SettingsPanel.NOTIFICATIONS -> AppSheet("Notificações", dismiss) {
            PanelRow {
                Text("Convites de sala", Modifier.weight(1f))
                Switch(state.notifyInvites, { action(AppAction.SetNotification("invites", it)) }, enabled = !state.busy)
            }
            PanelRow {
                Text("Solicitações de amizade", Modifier.weight(1f))
                Switch(state.notifyFriendships, { action(AppAction.SetNotification("friendships", it)) }, enabled = !state.busy)
            }
        }
        SettingsPanel.ABOUT -> AppSheet("Sobre o app", dismiss) {
            Brand(large = true)
            Text("Assista a vídeos com amigos em salas públicas ou privadas, com reprodução sincronizada e chat.")
        }
        null -> Unit
    }
}

@Composable
private fun MessagePreview(position: String, size: String, speed: String) {
    val motion = remember { Animatable(0f) }
    LaunchedEffect(position, size, speed) {
        while (true) {
            motion.snapTo(0f)
            motion.animateTo(1f, tween(messageOverlayDuration(speed), easing = LinearEasing))
            delay(500)
        }
    }
    Text("Prévia", fontWeight = FontWeight.SemiBold)
    BoxWithConstraints(
        Modifier.fillMaxWidth().height(76.dp).clip(CardShape).background(Background)
    ) {
        val width = minOf(maxWidth, 220.dp)
        Text(
            "Você: Vamos assistir!",
            modifier = Modifier
                .align(if (position == "top") Alignment.TopStart else Alignment.BottomStart)
                .offset(x = (maxWidth + width) * motion.value - width)
                .padding(vertical = 8.dp).width(width)
                .clip(CardShape).background(Panel).padding(horizontal = 10.dp, vertical = 4.dp),
            fontSize = messageOverlayFontSize(size),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
internal fun FriendsScreen(state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var code by rememberSaveable { mutableStateOf("") }
    var removingId by rememberSaveable { mutableStateOf<String?>(null) }
    var requestTab by rememberSaveable { mutableStateOf("incoming") }
    val context = LocalContext.current
    StandardPage("Amigos", back) {
        if (state.friendCode.isNotBlank()) {
            PanelRow {
                Column(Modifier.weight(1f)) {
                    Text("Seu código", color = Subtle)
                    Text(state.friendCode, fontWeight = FontWeight.Bold)
                }
                TextButton(onClick = { copyToClipboard(context, "Código de amigo", state.friendCode) }) {
                    Text("Copiar")
                }
            }
        }
        AppField(code, { code = it.take(32) }, "Código de amigo", Modifier.fillMaxWidth())
        ActionButton(
            "Enviar solicitação",
            { action(AppAction.RequestFriend(code.trim())) },
            Modifier.fillMaxWidth(),
            !state.busy && code.isNotBlank()
        )
        Text("Solicitações", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        PreferenceOptions(
            label = null,
            options = listOf("incoming" to "Recebidas", "sent" to "Enviadas"),
            selected = requestTab,
            update = { requestTab = it }
        )
        val requests = state.requests.filter { it.incoming == (requestTab == "incoming") }
        if (requests.isEmpty()) EmptyCard("Nenhuma solicitação")
        requests.forEach { request ->
            PanelRow {
                Avatar(request.nickname)
                Column(Modifier.weight(1f)) {
                    Text(request.nickname, fontWeight = FontWeight.Bold)
                    if (request.incoming) {
                        Row {
                            TextButton(
                                onClick = { action(AppAction.AnswerFriend(request.id, true)) },
                                enabled = !state.busy
                            ) { Text("Aceitar") }
                            TextButton(
                                onClick = { action(AppAction.AnswerFriend(request.id, false)) },
                                enabled = !state.busy
                            ) { Text("Recusar") }
                        }
                    } else {
                        TextButton(onClick = { action(AppAction.CancelFriend(request.id)) }, enabled = !state.busy) {
                            Text("Cancelar")
                        }
                    }
                }
            }
        }
        Text("Lista de amigos", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        if (state.friends.isEmpty()) EmptyCard("Você ainda não tem amigos")
        state.friends.forEach { friend ->
            PanelRow {
                Avatar(friend.nickname)
                Text(friend.nickname, Modifier.weight(1f), fontWeight = FontWeight.Bold)
                TextButton(onClick = { removingId = friend.id }, enabled = !state.busy) { Text("Remover") }
            }
        }
    }
    state.friends.firstOrNull { it.id == removingId }?.let { friend ->
        Confirm(
            "Remover amizade?",
            "Você e ${friend.nickname} serão removidos da lista de amigos um do outro.",
            "Remover",
            dismiss = { removingId = null }
        ) {
            removingId = null
            action(AppAction.RemoveFriend(friend.id))
        }
    }
}

@Composable
private fun SettingsRow(label: String, icon: ImageVector, onClick: () -> Unit) {
    PanelRow(onClick = onClick) {
        Icon(icon, null, tint = Accent)
        Text(label, Modifier.weight(1f), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Accent)
    }
}

@Composable
private fun PreferenceOptions(
    label: String?,
    options: List<Pair<String, String>>,
    selected: String,
    update: (String) -> Unit
) {
    Column {
        if (label != null) Text(label, fontWeight = FontWeight.SemiBold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            options.forEach { (value, text) ->
                FilterChip(selected = value == selected, onClick = { update(value) }, label = { Text(text) })
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun AppSheet(title: String, dismiss: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    ModalBottomSheet(onDismissRequest = dismiss, containerColor = Surface) {
        Column(
            Modifier.fillMaxWidth().heightIn(max = 640.dp).verticalScroll(rememberScrollState())
                .padding(start = 18.dp, end = 18.dp, bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            content()
        }
    }
}

@Composable
internal fun Confirm(
    title: String,
    message: String,
    label: String,
    dismiss: () -> Unit,
    enabled: Boolean = true,
    confirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = dismiss,
        title = { Text(title) },
        text = { Text(message) },
        dismissButton = { TextButton(onClick = dismiss) { Text("Cancelar") } },
        confirmButton = { TextButton(onClick = confirm, enabled = enabled) { Text(label) } }
    )
}
