package com.flops23.assistae.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.flops23.assistae.AppAction
import com.flops23.assistae.AppState
import com.flops23.assistae.Screen

@Composable
fun AssistAeScreen(
    state: AppState,
    onAction: (AppAction) -> Unit,
    playerContent: @Composable (Modifier) -> Unit
) {
    AssistAeTheme {
        ScreenBackground {
            val home = { onAction(AppAction.Navigate(Screen.HOME)) }
            BackHandler(state.screen in listOf(Screen.CREATE, Screen.JOIN, Screen.PUBLIC_ROOMS, Screen.SETTINGS)) {
                home()
            }
            BackHandler(state.screen == Screen.FRIENDS) {
                onAction(AppAction.Navigate(Screen.SETTINGS))
            }
            Box(Modifier.fillMaxSize()) {
                if (state.screen == Screen.ROOM && state.room != null) {
                    RoomScreen(state, state.room, onAction, playerContent)
                } else {
                    Box(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding()) {
                        when (state.screen) {
                            Screen.PROFILE -> ProfileScreen(state, onAction)
                            Screen.HOME -> HomeScreen(state, onAction)
                            Screen.CREATE -> CreateScreen(state, onAction, home)
                            Screen.JOIN -> JoinScreen(state, onAction, home)
                            Screen.PUBLIC_ROOMS -> PublicRoomsScreen(state, onAction, home)
                            Screen.SETTINGS -> SettingsScreen(state, onAction, home)
                            Screen.FRIENDS -> FriendsScreen(state, onAction) {
                                onAction(AppAction.Navigate(Screen.SETTINGS))
                            }
                            Screen.ROOM -> LinearProgressIndicator()
                        }
                    }
                }
                state.error?.let { message ->
                    AlertDialog(
                        onDismissRequest = { onAction(AppAction.DismissError) },
                        title = { Text("Não foi possível concluir") },
                        text = { Text(message) },
                        confirmButton = {
                            TextButton(onClick = { onAction(AppAction.DismissError) }) { Text("Entendi") }
                        }
                    )
                }
            }
        }
    }
}

internal fun copyToClipboard(context: Context, label: String, value: String) {
    context.getSystemService(ClipboardManager::class.java)
        ?.setPrimaryClip(ClipData.newPlainText(label, value))
}

internal fun shareCode(context: Context, code: String) {
    val send = Intent(Intent.ACTION_SEND)
        .setType("text/plain")
        .putExtra(Intent.EXTRA_TEXT, "Entre na minha sala no assistAe com o código $code.")
    context.startActivity(Intent.createChooser(send, "Compartilhar código da sala"))
}

internal fun String.characters(): Int = codePointCount(0, length)
