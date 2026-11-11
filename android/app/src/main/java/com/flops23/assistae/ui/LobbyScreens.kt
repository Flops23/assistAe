package com.flops23.assistae.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Login
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.VideoCall
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.flops23.assistae.AppAction
import com.flops23.assistae.AppState
import com.flops23.assistae.PublicRoom
import com.flops23.assistae.Screen

@Composable
internal fun HomeScreen(state: AppState, action: (AppAction) -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        Box(Modifier.fillMaxWidth().heightIn(min = 54.dp), contentAlignment = Alignment.Center) {
            IconButton(
                onClick = { action(AppAction.Navigate(Screen.SETTINGS)) },
                modifier = Modifier.align(Alignment.CenterStart)
            ) {
                Avatar(state.nickname)
            }
            Brand(large = true)
            IconButton(
                onClick = { action(AppAction.Navigate(Screen.SETTINGS)) },
                modifier = Modifier.align(Alignment.CenterEnd)
            ) {
                Icon(Icons.Filled.Settings, "Configurações", modifier = Modifier.size(26.dp))
            }
        }
        HomeIllustration(Modifier.fillMaxWidth().aspectRatio(3.55f))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            HomeTile(
                "Criar sala", "Inicie uma sessão com amigos",
                Icons.Filled.VideoCall, true, Modifier.weight(1f)
            ) {
                action(AppAction.Navigate(Screen.CREATE))
            }
            HomeTile(
                "Entrar em sala", "Use um código da sala ou convite",
                Icons.Filled.Group, false, Modifier.weight(1f)
            ) {
                action(AppAction.Navigate(Screen.JOIN))
            }
        }
        Spacer(Modifier.height(20.dp))
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Group, contentDescription = null, tint = Accent)
            Spacer(Modifier.width(7.dp))
            Text("Salas públicas", Modifier.weight(1f), fontSize = 21.sp, fontWeight = FontWeight.Bold)
            TextButton(onClick = { action(AppAction.Navigate(Screen.PUBLIC_ROOMS)) }) {
                Text("Ver todas", fontWeight = FontWeight.Bold)
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, modifier = Modifier.size(18.dp))
            }
        }
        if (state.busy && state.publicRooms.isEmpty()) {
            LinearProgressIndicator(Modifier.fillMaxWidth())
        } else if (state.publicRooms.isEmpty()) {
            EmptyCard("Nenhuma sala pública no momento")
        } else {
            state.publicRooms.take(3).forEach { room ->
                RoomCard(room, showPlay = true) { if (!state.busy) action(AppAction.JoinPublic(room.id)) }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun HomeIllustration(modifier: Modifier) {
    val context = LocalContext.current
    val bitmap = remember(context) {
        runCatching {
            context.assets.open("home-aprovada.png").use { BitmapFactory.decodeStream(it)?.asImageBitmap() }
        }.getOrNull()
    } ?: return
    Canvas(modifier) {
        // Use only the approved artwork between the header and the action cards.
        val startY = (bitmap.height * .112f).toInt()
        val endY = (bitmap.height * .271f).toInt()
        drawImage(
            image = bitmap,
            srcOffset = IntOffset(0, startY),
            srcSize = IntSize(bitmap.width, endY - startY),
            dstSize = IntSize(size.width.toInt(), size.height.toInt())
        )
    }
}

@Composable
private fun HomeTile(
    title: String,
    summary: String,
    icon: ImageVector,
    primary: Boolean,
    modifier: Modifier,
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier
            .clip(shape)
            .then(if (primary) Modifier.background(PurpleGradient) else Modifier.background(Surface))
            .border(1.dp, if (primary) Accent else Outline, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .heightIn(min = 112.dp)
            .padding(horizontal = 8.dp, vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterVertically)
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(31.dp))
        Text(title, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
        Text(summary, fontSize = 12.sp, color = TextLight, textAlign = TextAlign.Center, lineHeight = 14.sp)
    }
}

@Composable
internal fun ProfileScreen(state: AppState, action: (AppAction) -> Unit) {
    var nickname by rememberSaveable { mutableStateOf(state.nickname) }
    val context = LocalContext.current
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically)
    ) {
        Brand(large = true)
        if (state.betaId != null) {
            Text("Acesso ao teste fechado", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(
                "Envie seu identificador a quem convidou você para liberar o acesso.",
                color = Subtle,
                textAlign = TextAlign.Center
            )
            Text(state.betaId, color = Accent, textAlign = TextAlign.Center)
            TextButton(onClick = { copyToClipboard(context, "Identificador do teste", state.betaId) }) {
                Text("Copiar identificador")
            }
            ActionButton("Verificar acesso", { action(AppAction.Retry) }, Modifier.fillMaxWidth(), !state.busy)
        } else {
            AppField(nickname, { if (it.characters() <= 24) nickname = it }, "Seu apelido", Modifier.fillMaxWidth())
            ActionButton(
                "Continuar",
                { action(AppAction.EnsureProfile(nickname.trim())) },
                Modifier.fillMaxWidth(),
                !state.busy && nickname.trim().characters() in 2..24
            )
        }
        if (state.busy) CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
    }
}

@Composable
internal fun CreateScreen(state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var name by rememberSaveable { mutableStateOf("") }
    var isPublic by rememberSaveable { mutableStateOf(true) }
    Column(Modifier.fillMaxSize().padding(horizontal = 18.dp)) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            PageHeader("Criar sala", back)
            AppField(name, { if (it.characters() <= 60) name = it }, "Nome da sala", Modifier.fillMaxWidth())
            PanelRow {
                Icon(Icons.Filled.Public, null)
                Text("Sala pública", Modifier.weight(1f), style = MaterialTheme.typography.titleMedium)
                Switch(checked = isPublic, onCheckedChange = { isPublic = it }, enabled = !state.busy)
            }
        }
        ActionButton(
            if (state.busy) "Criando sala…" else "Criar sala",
            { action(AppAction.CreateRoom(name.trim(), isPublic)) },
            Modifier.fillMaxWidth().padding(vertical = 16.dp),
            !state.busy && name.trim().characters() in 2..60,
            leading = { Icon(Icons.Filled.VideoCall, null) }
        )
    }
}

@Composable
internal fun JoinScreen(state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var code by rememberSaveable { mutableStateOf("") }
    StandardPage("Entrar em sala", back) {
        AppField(code, { code = it.take(32) }, "Código da sala", Modifier.fillMaxWidth())
        ActionButton(
            if (state.busy) "Entrando…" else "Entrar",
            { action(AppAction.JoinCode(code.trim())) },
            Modifier.fillMaxWidth(),
            !state.busy && code.isNotBlank(),
            leading = { Icon(Icons.AutoMirrored.Filled.Login, null) }
        )
        Text("Convites de amigos", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        if (state.invites.isEmpty()) {
            EmptyCard("Nenhum convite de amigo")
        }
        state.invites.forEach { invite ->
            PanelRow {
                Avatar(invite.nickname)
                Column(Modifier.weight(1f)) {
                    Text(invite.nickname, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(invite.roomName, color = Subtle, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
                ActionButton("Entrar", { action(AppAction.JoinInvite(invite.id)) }, enabled = !state.busy)
            }
        }
    }
}

@Composable
internal fun PublicRoomsScreen(state: AppState, action: (AppAction) -> Unit, back: () -> Unit) {
    var query by rememberSaveable { mutableStateOf("") }
    var lastQuery by rememberSaveable { mutableStateOf("") }
    LaunchedEffect(query) {
        val trimmed = query.trim()
        if (trimmed != lastQuery) {
            lastQuery = trimmed
            action(AppAction.SearchRooms(trimmed))
        }
    }
    Column(Modifier.fillMaxSize().padding(horizontal = 18.dp)) {
        PageHeader("Salas públicas", back)
        AppField(
            query, { query = it.take(60) }, "Buscar sala", Modifier.fillMaxWidth(),
            leading = { Icon(Icons.Filled.Search, null) }
        )
        Spacer(Modifier.height(12.dp))
        if (state.busy) LinearProgressIndicator(Modifier.fillMaxWidth())
        if (state.publicRooms.isEmpty() && !state.busy) {
            EmptyCard(if (query.isBlank()) "Nenhuma sala pública no momento" else "Nenhuma sala encontrada")
        }
        LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(state.publicRooms, key = { it.id }) { room ->
                RoomCard(room) { if (!state.busy) action(AppAction.JoinPublic(room.id)) }
            }
            item { Spacer(Modifier.height(10.dp)) }
        }
    }
}

@Composable
internal fun StandardPage(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 18.dp, vertical = 6.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        PageHeader(title, back)
        content()
        Spacer(Modifier.height(6.dp))
    }
}

@Composable
internal fun EmptyCard(message: String) {
    PanelRow { Text(message, color = Subtle, modifier = Modifier.padding(4.dp)) }
}

@Composable
private fun RoomCard(room: PublicRoom, showPlay: Boolean = false, onClick: () -> Unit) {
    PanelRow(onClick = onClick) {
        Box(
            Modifier.width(if (showPlay) 72.dp else 88.dp).height(44.dp)
                .clip(RoundedCornerShape(10.dp)).background(Panel),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Image, null, tint = Accent)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(room.name, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                Icon(Icons.Filled.Group, null, tint = Accent, modifier = Modifier.size(16.dp))
                Text(
                    if (room.connected == 1) "1 pessoa" else "${room.connected} pessoas",
                    color = Subtle,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
        if (showPlay) {
            Box(Modifier.clip(CardShape).background(PurpleGradient).padding(horizontal = 7.dp, vertical = 3.dp)) {
                Icon(Icons.Filled.PlayArrow, null)
            }
        }
    }
}
