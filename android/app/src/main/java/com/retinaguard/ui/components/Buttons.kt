package com.retinaguard.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.VodafoneRed

/** Editorial primary CTA — red pill button. */
@Composable
fun RedPillButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(60.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = VodafoneRed,
            contentColor = CanvasWhite,
            disabledContainerColor = VodafoneRed.copy(alpha = 0.4f),
            disabledContentColor = CanvasWhite,
        ),
        contentPadding = PaddingValues(horizontal = 24.dp, vertical = 16.dp),
        modifier = modifier.heightIn(min = 48.dp),
    ) {
        Text(
            text = text,
            fontSize = 14.4.sp,
            fontWeight = FontWeight.W700,
            textAlign = TextAlign.Center,
        )
    }
}

/** Utility / form CTA — red rectangle button. */
@Composable
fun RedRectangleButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(2.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = VodafoneRed,
            contentColor = CanvasWhite,
        ),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        modifier = modifier.heightIn(min = 44.dp),
    ) {
        Text(text = text, fontSize = 14.4.sp, fontWeight = FontWeight.W700)
    }
}

/** Secondary form action — ghost outlined button. */
@Composable
fun GhostRectangleButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onDark: Boolean = false,
) {
    val border = if (onDark) CanvasWhite else Charcoal
    val bg = if (onDark) Charcoal else CanvasWhite
    val fg = if (onDark) CanvasWhite else Charcoal
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        shape = RoundedCornerShape(2.dp),
        border = BorderStroke(1.dp, border),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = bg,
            contentColor = fg,
        ),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        modifier = modifier.heightIn(min = 44.dp),
    ) {
        Text(text = text, fontSize = 14.4.sp, fontWeight = FontWeight.W700)
    }
}
