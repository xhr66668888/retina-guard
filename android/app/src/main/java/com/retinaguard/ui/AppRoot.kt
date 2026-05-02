package com.retinaguard.ui

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.retinaguard.data.AppSettings
import com.retinaguard.data.ReminderStyle
import com.retinaguard.data.SessionState
import com.retinaguard.data.SoundMode
import com.retinaguard.data.TodayStats
import com.retinaguard.permission.PermissionsState
import com.retinaguard.ui.onboarding.OnboardingScreen
import com.retinaguard.ui.schedule.ScheduleScreen
import com.retinaguard.ui.settings.SettingsScreen
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed
import com.retinaguard.ui.today.TodayScreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppRoot(
    settings: AppSettings,
    session: SessionState,
    stats: TodayStats,
    permissions: PermissionsState,
    onStart: () -> Unit,
    onStop: () -> Unit,
    onTakeBreakNow: () -> Unit,
    onIntervalChange: (Int) -> Unit,
    onReminderStyleChange: (ReminderStyle) -> Unit,
    onSoundModeChange: (SoundMode) -> Unit,
    onVibrationChange: (Boolean) -> Unit,
    onUsageAwareChange: (Boolean) -> Unit,
    onExcludedPackagesChange: (Set<String>) -> Unit,
    onDailyScheduleChange: (Boolean) -> Unit,
    onQuietHoursChange: (Boolean) -> Unit,
    onActiveDaysMaskChange: (Int) -> Unit,
    onOnboardingDone: () -> Unit,
    onResetStats: () -> Unit,
    onRefreshPermissions: () -> Unit,
) {
    if (!settings.onboardingDone) {
        OnboardingScreen(
            permissions = permissions,
            onRefresh = onRefreshPermissions,
            onFinish = onOnboardingDone,
        )
        return
    }

    var tab by rememberSaveable { mutableIntStateOf(0) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = CanvasWhite,
        bottomBar = {
            NavigationBar(
                containerColor = CanvasWhite,
                contentColor = Charcoal,
                tonalElevation = 0.dp,
            ) {
                BottomTab.entries.forEachIndexed { index, item ->
                    NavigationBarItem(
                        selected = tab == index,
                        onClick = { tab = index },
                        icon = { Icon(item.icon(), contentDescription = item.label) },
                        label = { Text(item.label) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = VodafoneRed,
                            selectedTextColor = VodafoneRed,
                            unselectedIconColor = SecondaryGrey,
                            unselectedTextColor = SecondaryGrey,
                            indicatorColor = CanvasWhite,
                        ),
                    )
                }
            }
        }
    ) { inner ->
        when (tab) {
            0 -> TodayScreen(
                settings = settings,
                session = session,
                stats = stats,
                permissions = permissions,
                onStart = onStart,
                onStop = onStop,
                onTakeBreakNow = onTakeBreakNow,
                onIntervalChange = onIntervalChange,
                onOpenSetup = { tab = 2 },
                contentPadding = inner,
            )
            1 -> ScheduleScreen(
                settings = settings,
                onDailyScheduleChange = onDailyScheduleChange,
                onQuietHoursChange = onQuietHoursChange,
                onActiveDaysMaskChange = onActiveDaysMaskChange,
                contentPadding = inner,
            )
            else -> SettingsScreen(
                settings = settings,
                permissions = permissions,
                onReminderStyleChange = onReminderStyleChange,
                onSoundModeChange = onSoundModeChange,
                onVibrationChange = onVibrationChange,
                onUsageAwareChange = onUsageAwareChange,
                onExcludedPackagesChange = onExcludedPackagesChange,
                onResetStats = onResetStats,
                contentPadding = inner,
            )
        }
    }
}

private enum class BottomTab(val label: String, val icon: () -> androidx.compose.ui.graphics.vector.ImageVector) {
    Today("Today", { Icons.Filled.AccessTime }),
    Schedule("Schedule", { Icons.Filled.CalendarMonth }),
    Settings("Settings", { Icons.Filled.Settings });
}
