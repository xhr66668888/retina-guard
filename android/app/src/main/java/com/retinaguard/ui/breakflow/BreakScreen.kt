package com.retinaguard.ui.breakflow

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.retinaguard.ui.components.GhostRectangleButton
import com.retinaguard.ui.components.RedBand
import com.retinaguard.ui.components.RedPillButton
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.SecondaryGrey
import kotlinx.coroutines.delay

@Composable
fun BreakScreen(
    breakSeconds: Int,
    snoozeMinutes: Int,
    onComplete: () -> Unit,
    onSnooze: () -> Unit,
    onSkip: () -> Unit,
) {
    var remaining by remember { mutableIntStateOf(breakSeconds) }
    val haptics = LocalHapticFeedback.current
    LaunchedEffect(Unit) {
        while (remaining > 0) {
            delay(1_000L)
            remaining -= 1
        }
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        delay(800L)
        onComplete()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Charcoal)
            .statusBarsPadding(),
    ) {
        RedBand(height = 40.dp)

        Spacer(Modifier.weight(1f))

        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = remaining.toString(),
                color = CanvasWhite,
                fontWeight = FontWeight.W800,
                fontSize = 160.sp,
                textAlign = TextAlign.Center,
            )
        }

        Spacer(Modifier.height(16.dp))

        Text(
            text = "LOOK FAR AWAY",
            color = CanvasWhite,
            style = MaterialTheme.typography.headlineLarge,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
        )

        Spacer(Modifier.height(12.dp))

        Text(
            text = "Relax your eyes and breathe.",
            color = SecondaryGrey,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 32.dp),
        )

        Spacer(Modifier.weight(1f))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            RedPillButton(
                text = "Done",
                onClick = onComplete,
                modifier = Modifier.fillMaxWidth(),
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                GhostRectangleButton(
                    text = "Snooze ${snoozeMinutes}m",
                    onClick = onSnooze,
                    modifier = Modifier.weight(1f),
                    onDark = true,
                )
                GhostRectangleButton(
                    text = "Skip",
                    onClick = onSkip,
                    modifier = Modifier.weight(1f),
                    onDark = true,
                )
            }
        }
    }
}
