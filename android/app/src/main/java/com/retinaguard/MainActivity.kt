package com.retinaguard

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleEventEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.retinaguard.ui.AppRoot
import com.retinaguard.ui.MainViewModel
import com.retinaguard.ui.theme.RetinaGuardTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            RetinaGuardTheme {
                val vm: MainViewModel = viewModel()
                val settings by vm.settings.collectAsState()
                val session by vm.session.collectAsState()
                val stats by vm.stats.collectAsState()
                val perms by vm.permissions.collectAsState()

                LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
                    vm.refreshPermissions()
                }

                AppRoot(
                    settings = settings,
                    session = session,
                    stats = stats,
                    permissions = perms,
                    onStart = vm::startProtection,
                    onStop = vm::stopProtection,
                    onTakeBreakNow = vm::takeBreakNow,
                    onIntervalChange = vm::setInterval,
                    onReminderStyleChange = vm::setReminderStyle,
                    onSoundModeChange = vm::setSoundMode,
                    onVibrationChange = vm::setVibration,
                    onUsageAwareChange = vm::setUsageAwareEnabled,
                    onExcludedPackagesChange = vm::setExcludedPackages,
                    onDailyScheduleChange = vm::setDailyScheduleEnabled,
                    onQuietHoursChange = vm::setQuietHoursEnabled,
                    onActiveDaysMaskChange = vm::setActiveDaysMask,
                    onOnboardingDone = { vm.setOnboardingDone(true) },
                    onResetStats = vm::resetTodayStats,
                    onRefreshPermissions = vm::refreshPermissions,
                )
            }
        }
    }
}
