package com.flops23.assistae.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

internal val Background = Color(0xFF100719)
internal val Surface = Color(0xFF20132D)
internal val Panel = Color(0xFF2A193A)
internal val Outline = Color(0xFF744B8D)
internal val Accent = Color(0xFFD18AF5)
internal val Subtle = Color(0xFFDCC8EA)
internal val TextLight = Color(0xFFFCF7FF)

internal val PurpleGradient = Brush.linearGradient(
    listOf(Color(0xFFB83CE5), Color(0xFF8C24E1), Color(0xFF5E0AB9))
)
internal val ScreenGradient = Brush.linearGradient(
    0f to Color(0xFF10061A),
    0.33f to Color(0xFF230840),
    0.58f to Color(0xFF11071A),
    1f to Color(0xFF1D0B32)
)
internal val CardShape = RoundedCornerShape(16.dp)

@Composable
internal fun AssistAeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Accent,
            onPrimary = Color(0xFF321048),
            primaryContainer = Color(0xFF571786),
            onPrimaryContainer = TextLight,
            secondary = Color(0xFFCEACE2),
            background = Background,
            onBackground = TextLight,
            surface = Surface,
            onSurface = TextLight,
            surfaceVariant = Panel,
            onSurfaceVariant = Subtle,
            outline = Outline
        ),
        content = content
    )
}

@Composable
internal fun Brand(large: Boolean = false) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = buildAnnotatedString {
                withStyle(SpanStyle(color = TextLight)) { append("assist") }
                withStyle(SpanStyle(color = Color(0xFFB941EF))) { append("Ae") }
            },
            fontSize = if (large) 34.sp else 28.sp,
            lineHeight = if (large) 38.sp else 32.sp,
            letterSpacing = (-0.8).sp,
            fontWeight = FontWeight.ExtraBold
        )
        if (large) {
            Text("assista com amigos", color = Subtle, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
internal fun PageHeader(title: String, back: () -> Unit) {
    Column {
        Box(Modifier.fillMaxWidth().heightIn(min = 54.dp), contentAlignment = Alignment.Center) {
            IconButton(onClick = back, modifier = Modifier.align(Alignment.CenterStart)) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Voltar")
            }
            Brand()
        }
        Text(
            title,
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(top = 10.dp, bottom = 12.dp)
        )
    }
}

@Composable
internal fun ActionButton(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leading: (@Composable () -> Unit)? = null
) {
    Row(
        modifier = modifier
            .clip(CardShape)
            .then(if (enabled) Modifier.background(PurpleGradient) else Modifier.background(Panel))
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .heightIn(min = 48.dp)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally)
    ) {
        leading?.invoke()
        Text(
            label,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = if (enabled) TextLight else Subtle
        )
    }
}

@Composable
internal fun AppField(
    value: String,
    update: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
    leading: (@Composable () -> Unit)? = null
) {
    OutlinedTextField(
        value = value,
        onValueChange = update,
        modifier = modifier,
        label = { Text(label) },
        singleLine = singleLine,
        maxLines = if (singleLine) 1 else 3,
        leadingIcon = leading,
        shape = CardShape,
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = Panel,
            unfocusedContainerColor = Surface,
            focusedBorderColor = Accent,
            unfocusedBorderColor = Outline,
            unfocusedLabelColor = Subtle
        )
    )
}

@Composable
internal fun PanelRow(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    content: @Composable RowScope.() -> Unit
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(CardShape)
            .background(Surface)
            .border(1.dp, Outline, CardShape)
            .then(if (onClick == null) Modifier else Modifier.clickable(role = Role.Button, onClick = onClick))
            .padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content
    )
}

@Composable
internal fun Avatar(nickname: String, modifier: Modifier = Modifier) {
    Box(
        modifier.size(38.dp).clip(CircleShape).background(PurpleGradient),
        contentAlignment = Alignment.Center
    ) {
        Text(
            nickname.trim().take(1).uppercase().ifBlank { "A" },
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = TextLight
        )
    }
}

@Composable
internal fun ScreenBackground(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize().background(ScreenGradient), propagateMinConstraints = true) {
        content()
    }
}
