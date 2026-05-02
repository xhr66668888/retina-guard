package com.retinaguard.ui.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.retinaguard.data.AppSettings
import com.retinaguard.data.IntervalChoices
import com.retinaguard.data.SessionState
import com.retinaguard.data.TodayStats
import com.retinaguard.permission.PermissionsState
import com.retinaguard.ui.components.GhostRectangleButton
import com.retinaguard.ui.components.RedBand
import com.retinaguard.ui.components.RedPillButton
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.LightNeutral
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun TodayScreen(
    settings: AppSettings,
    session: SessionState,
    stats: TodayStats,
    permissions: PermissionsState,
    onStart: () -> Unit,
    onStop: () -> Unit,
    onTakeBreakNow: () -> Unit,
    onIntervalChange: (Int) -> Unit,
    onOpenSetup: () -> Unit,
    contentPadding: PaddingValues,
) {
    var nowMs by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(session.protectionRunning, session.nextDueAtMillis) {
        while (true) {
            nowMs = System.currentTimeMillis()
            delay(500L)
        }
    }

    val running = session.protectionRunning
    val remainingSec = if (running) {
        ((session.nextDueAtMillis - nowMs) / 1000L).coerceAtLeast(0L)
    } else {
        settings.intervalMinutes * 60L
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(contentPadding)
            .padding(bottom = 24.dp),
    ) {
        Spacer(Modifier.height(12.dp))

        Text(
            text = "RETINA GUARD",
            style = MaterialTheme.typography.labelLarge,
            color = Charcoal,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
            textAlign = TextAlign.Start,
        )

        Spacer(Modifier.height(28.dp))

        TimerHero(remainingSec = remainingSec, running = running, dueAt = session.nextDueAtMillis)

        Spacer(Modifier.height(28.dp))

        Box(Modifier.padding(horizontal = 24.dp)) {
            if (running) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    GhostRectangleButton(
                        text = "Stop",
                        onClick = onStop,
                        modifier = Modifier.weight(1f),
                    )
                    RedPillButton(
                        text = "Take break now",
                        onClick = onTakeBreakNow,
                        modifier = Modifier.weight(1f),
                    )
                }
            } else {
                RedPillButton(
                    text = "Start protection",
                    onClick = onStart,
                    enabled = permissions.readyForBasic,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        if (!running) {
            Spacer(Modifier.height(28.dp))
            IntervalPicker(
                current = settings.intervalMinutes,
                onSelect = onIntervalChange,
            )
        }

        Spacer(Modifier.height(32.dp))
        RedBand()
        Spacer(Modifier.height(32.dp))

        SectionHeading("Today")
        Spacer(Modifier.height(12.dp))
        StatsRow(stats)

        Spacer(Modifier.height(32.dp))
        SectionHeading("Reliability")
        Spacer(Modifier.height(12.dp))

        ReliabilityCard(
            permissions = permissions,
            onOpenSetup = onOpenSetup,
        )

        if (running) {
            Spacer(Modifier.height(28.dp))
            SectionHeading("Background")
            Spacer(Modifier.height(8.dp))
            BackgroundStatusRow("Foreground service", "running")
            BackgroundStatusRow(
                "Exact alarm",
                if (session.nextDueAtMillis > 0) "scheduled" else "not scheduled",
            )
        }
    }
}

@Composable
private fun TimerHero(remainingSec: Long, running: Boolean, dueAt: Long) {
    val mins = remainingSec / 60
    val secs = remainingSec % 60
    val timer = "%02d:%02d".format(mins, secs)
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
    ) {
        Text(
            text = timer,
            color = Charcoal,
            fontWeight = FontWeight.W800,
            fontSize = 80.sp,
            textAlign = TextAlign.Start,
        )
        Spacer(Modifier.height(8.dp))
        val sub = if (running) {
            val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(dueAt))
            "next break at $time"
        } else {
            "until your next eye break"
        }
        Text(
            sub,
            color = SecondaryGrey,
            style = MaterialTheme.typography.bodyLarge,
        )
    }
}

@Composable
private fun IntervalPicker(current: Int, onSelect: (Int) -> Unit) {
    Column(Modifier.padding(horizontal = 24.dp)) {
        Text(
            "INTERVAL",
            style = MaterialTheme.typography.labelMedium,
            color = SecondaryGrey,
        )
        Spacer(Modifier.height(8.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            IntervalChoices.forEach { value ->
                val selected = value == current
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(44.dp)
                        .background(
                            if (selected) VodafoneRed else LightNeutral,
                            RoundedCornerShape(2.dp),
                        )
                        .clickable { onSelect(value) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "$value",
                        color = if (selected) CanvasWhite else Charcoal,
                        style = MaterialTheme.typography.labelLarge,
                    )
                }
            }
        }
        Spacer(Modifier.height(6.dp))
        Text(
            "minutes between breaks",
            style = MaterialTheme.typography.bodySmall,
            color = SecondaryGrey,
        )
    }
}

@Composable
private fun StatsRow(stats: TodayStats) {
    val protectedH = stats.protectedSeconds / 3600
    val protectedM = (stats.protectedSeconds % 3600) / 60
    val protectedLabel = if (protectedH > 0) "${protectedH}h ${protectedM}m" else "${protectedM}m"
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        StatTile("Completed", stats.completed.toString())
        StatTile("Skipped", stats.skipped.toString())
        StatTile("Protected", protectedLabel)
    }
}

@Composable
private fun StatTile(label: String, value: String) {
    Column {
        Text(
            value,
            color = Charcoal,
            fontWeight = FontWeight.W800,
            fontSize = 28.sp,
        )
        Text(
            label.uppercase(),
            color = SecondaryGrey,
            style = MaterialTheme.typography.labelMedium,
        )
    }
}

@Composable
private fun SectionHeading(text: String) {
    Text(
        text,
        color = Charcoal,
        style = MaterialTheme.typography.headlineMedium,
        modifier = Modifier.padding(horizontal = 24.dp),
    )
}

@Composable
private fun ReliabilityCard(
    permissions: PermissionsState,
    onOpenSetup: () -> Unit,
) {
    val ready = permissions.readyCount
    val total = permissions.totalCount
    val complete = ready == total
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .border(1.dp, LightNeutral, RoundedCornerShape(6.dp))
            .clickable(onClick = onOpenSetup)
            .padding(16.dp),
    ) {
        Text(
            text = if (complete) "All permissions ready" else "$ready / $total permissions ready",
            color = Charcoal,
            style = MaterialTheme.typography.titleLarge,
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = if (complete) {
                "Retina Guard can behave like a clock alarm."
            } else {
                "Finish setup to make reminders more reliable."
            },
            color = SecondaryGrey,
            style = MaterialTheme.typography.bodyMedium,
        )
        Spacer(Modifier.height(12.dp))
        Text(
            text = if (complete) "Review permissions" else "Finish setup",
            color = VodafoneRed,
            style = MaterialTheme.typography.labelLarge,
        )
    }
}

@Composable
private fun BackgroundStatusRow(name: String, value: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(name, color = Charcoal, style = MaterialTheme.typography.bodyMedium)
        Text(value, color = SecondaryGrey, style = MaterialTheme.typography.labelLarge)
    }
}
