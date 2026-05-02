package com.retinaguard.ui

import android.app.Application
import android.content.Intent
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.retinaguard.BreakActivity
import com.retinaguard.data.AppSettings
import com.retinaguard.data.PreferencesRepository
import com.retinaguard.data.ReminderStyle
import com.retinaguard.data.SessionState
import com.retinaguard.data.SoundMode
import com.retinaguard.data.TodayStats
import com.retinaguard.permission.PermissionsState
import com.retinaguard.service.ProtectionService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class MainViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = PreferencesRepository.get(app)

    val settings: StateFlow<AppSettings> = repo.settings.stateIn(
        viewModelScope, SharingStarted.Eagerly, AppSettings()
    )
    val session: StateFlow<SessionState> = repo.session.stateIn(
        viewModelScope, SharingStarted.Eagerly, SessionState()
    )
    val stats: StateFlow<TodayStats> = repo.stats.stateIn(
        viewModelScope, SharingStarted.Eagerly, TodayStats()
    )

    private val _permissions = MutableStateFlow(PermissionsState.read(app))
    val permissions: StateFlow<PermissionsState> = _permissions

    fun refreshPermissions() {
        _permissions.value = PermissionsState.read(getApplication())
    }

    fun startProtection() {
        ProtectionService.start(getApplication())
    }

    fun stopProtection() {
        ProtectionService.stop(getApplication())
    }

    fun takeBreakNow() {
        val app = getApplication<Application>()
        app.startActivity(
            BreakActivity.startIntent(app)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    fun setInterval(minutes: Int) {
        viewModelScope.launch {
            repo.setInterval(minutes)
            // If running, defer change to next cycle by adjusting nextDueAt now.
            val s = session.value
            if (s.protectionRunning) {
                val due = System.currentTimeMillis() + minutes * 60_000L
                repo.setNextDueAt(due)
                com.retinaguard.alarm.AlarmScheduler.schedule(getApplication(), due)
            }
        }
    }

    fun setReminderStyle(style: ReminderStyle) {
        viewModelScope.launch { repo.setReminderStyle(style) }
    }

    fun setSoundMode(mode: SoundMode) {
        viewModelScope.launch { repo.setSoundMode(mode) }
    }

    fun setVibration(enabled: Boolean) {
        viewModelScope.launch { repo.setVibration(enabled) }
    }

    fun setUsageAwareEnabled(enabled: Boolean) {
        viewModelScope.launch { repo.setUsageAwareEnabled(enabled) }
    }

    fun setExcludedPackages(packages: Set<String>) {
        viewModelScope.launch { repo.setExcludedPackages(packages) }
    }

    fun setOnboardingDone(done: Boolean) {
        viewModelScope.launch { repo.setOnboardingDone(done) }
    }

    fun setDailyScheduleEnabled(enabled: Boolean) {
        viewModelScope.launch { repo.setDailyScheduleEnabled(enabled) }
    }

    fun setQuietHoursEnabled(enabled: Boolean) {
        viewModelScope.launch { repo.setQuietHoursEnabled(enabled) }
    }

    fun setActiveDaysMask(mask: Int) {
        viewModelScope.launch { repo.setActiveDaysMask(mask) }
    }

    fun resetTodayStats() {
        viewModelScope.launch { repo.resetTodayStats() }
    }
}
