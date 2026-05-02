package com.retinaguard.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColors = lightColorScheme(
    primary = VodafoneRed,
    onPrimary = CanvasWhite,
    primaryContainer = VodafoneRed,
    onPrimaryContainer = CanvasWhite,
    secondary = Charcoal,
    onSecondary = CanvasWhite,
    background = CanvasWhite,
    onBackground = Charcoal,
    surface = CanvasWhite,
    onSurface = Charcoal,
    surfaceVariant = LightNeutral,
    onSurfaceVariant = Charcoal,
    outline = SecondaryGrey,
    error = VodafoneRed,
    onError = CanvasWhite,
)

@Composable
fun RetinaGuardTheme(
    darkSurface: Boolean = false,
    content: @Composable () -> Unit
) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            val statusBg = if (darkSurface) Charcoal else CanvasWhite
            window.statusBarColor = statusBg.toArgb()
            window.navigationBarColor = statusBg.toArgb()
            val controller = WindowCompat.getInsetsController(window, view)
            controller.isAppearanceLightStatusBars = !darkSurface
            controller.isAppearanceLightNavigationBars = !darkSurface
        }
    }

    MaterialTheme(
        colorScheme = LightColors,
        typography = AppTypography,
        content = content
    )
}

// Radius scale tokens (Compose-side helpers).
object AppRadius {
    val ButtonTight = 2
    val Card = 6
    val GlassPill = 24
    val BadgePill = 32
    val CtaPill = 60
}
