package com.retinaguard.ui.schedule

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.retinaguard.data.AppSettings
import com.retinaguard.ui.components.RedBand
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.LightNeutral
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed

@Composable
fun ScheduleScreen(
    settings: AppSettings,
    onDailyScheduleChange: (Boolean) -> Unit,
    onQuietHoursChange: (Boolean) -> Unit,
    onActiveDaysMaskChange: (Int) -> Unit,
    contentPadding: PaddingValues,
) {
    val activeDays = selectedDays(settings.activeDaysMask)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(contentPadding)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(12.dp))
        Text(
            "SCHEDULE",
            style = MaterialTheme.typography.labelLarge,
            color = Charcoal,
            modifier = Modifier.padding(horizontal = 24.dp),
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Make breaks happen automatically on a daily window.",
            color = SecondaryGrey,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(horizontal = 24.dp),
        )

        Spacer(Modifier.height(24.dp))
        RedBand()
        Spacer(Modifier.height(24.dp))

        ScheduleRow(
            title = "Daily protection",
            subtitle = if (settings.dailyScheduleEnabled)
                "Active ${activeDays.size} days/week"
            else
                "Off — start manually from Today",
            checked = settings.dailyScheduleEnabled,
            onCheckedChange = onDailyScheduleChange,
        )

        DaysRow(
            selected = activeDays,
            onToggle = { day ->
                onActiveDaysMaskChange(toggleDay(settings.activeDaysMask, day))
            },
            enabled = settings.dailyScheduleEnabled,
        )

        InfoRow("Start time", "09:00")
        InfoRow("End time", "18:00")
        InfoRow("Interval", "${settings.intervalMinutes} min")

        ScheduleRow(
            title = "Quiet hours",
            subtitle = if (settings.quietHoursEnabled) "Mute reminders 22:00 - 08:00" else "Off",
            checked = settings.quietHoursEnabled,
            onCheckedChange = onQuietHoursChange,
        )

        Spacer(Modifier.height(48.dp))

        Text(
            "Daily windows are saved for the background engine. Manual Start remains available anytime.",
            style = MaterialTheme.typography.bodySmall,
            color = SecondaryGrey,
            modifier = Modifier.padding(horizontal = 24.dp),
            textAlign = TextAlign.Start,
        )
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun ScheduleRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, color = Charcoal, style = MaterialTheme.typography.titleMedium)
            Text(subtitle, color = SecondaryGrey, style = MaterialTheme.typography.bodySmall)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = CanvasWhite,
                checkedTrackColor = VodafoneRed,
                checkedBorderColor = VodafoneRed,
            ),
        )
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun InfoRow(name: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(name, color = Charcoal, style = MaterialTheme.typography.titleMedium)
        Text(value, color = SecondaryGrey, style = MaterialTheme.typography.labelLarge)
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun DaysRow(
    selected: Set<String>,
    onToggle: (String) -> Unit,
    enabled: Boolean,
) {
    val days = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        days.forEach { d ->
            val isSelected = d in selected && enabled
            DayChip(label = d, selected = isSelected, enabled = enabled, onClick = { onToggle(d) })
        }
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun DayChip(
    label: String,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    val bg = when {
        !enabled -> LightNeutral
        selected -> VodafoneRed
        else -> LightNeutral
    }
    val fg = when {
        !enabled -> SecondaryGrey
        selected -> CanvasWhite
        else -> Charcoal
    }
    Row(
        modifier = Modifier
            .height(36.dp)
            .padding(end = 0.dp),
    ) {
        androidx.compose.material3.Surface(
            color = bg,
            shape = androidx.compose.foundation.shape.RoundedCornerShape(2.dp),
            onClick = onClick,
            enabled = enabled,
        ) {
            androidx.compose.foundation.layout.Box(
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = label.first().toString(),
                    color = fg,
                    style = MaterialTheme.typography.labelMedium,
                )
            }
        }
    }
}

private val dayOrder = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")

private fun selectedDays(mask: Int): Set<String> =
    dayOrder.filterIndexed { index, _ -> mask and (1 shl index) != 0 }.toSet()

private fun toggleDay(mask: Int, day: String): Int {
    val index = dayOrder.indexOf(day)
    if (index < 0) return mask
    return mask xor (1 shl index)
}
