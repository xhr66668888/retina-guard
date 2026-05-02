package com.retinaguard.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private val Context.dataStore by preferencesDataStore(name = "retina_guard")

private object Keys {
    val IntervalMinutes = intPreferencesKey("interval_minutes")
    val BreakSeconds = intPreferencesKey("break_seconds")
    val SnoozeMinutes = intPreferencesKey("snooze_minutes")
    val ReminderStyle = stringPreferencesKey("reminder_style")
    val SoundMode = stringPreferencesKey("sound_mode")
    val VibrationEnabled = booleanPreferencesKey("vibration_enabled")
    val OnboardingDone = booleanPreferencesKey("onboarding_done")
    val DailyScheduleEnabled = booleanPreferencesKey("daily_schedule_enabled")
    val QuietHoursEnabled = booleanPreferencesKey("quiet_hours_enabled")
    val ActiveDaysMask = intPreferencesKey("active_days_mask")
    val UsageAwareEnabled = booleanPreferencesKey("usage_aware_enabled")
    val ExcludedPackages = stringPreferencesKey("excluded_packages")

    val ProtectionRunning = booleanPreferencesKey("protection_running")
    val NextDueAt = longPreferencesKey("next_due_at")
    val ProtectionStartedAt = longPreferencesKey("protection_started_at")
    val ConsecutiveMissed = intPreferencesKey("consecutive_missed")
    val ReminderOutstanding = booleanPreferencesKey("reminder_outstanding")
    val AccumulatedScreenMs = longPreferencesKey("accumulated_screen_ms")

    val StatsDate = stringPreferencesKey("stats_date")
    val StatsCompleted = intPreferencesKey("stats_completed")
    val StatsSkipped = intPreferencesKey("stats_skipped")
    val StatsMissed = intPreferencesKey("stats_missed")
    val StatsProtectedSec = longPreferencesKey("stats_protected_sec")
}

class PreferencesRepository(private val context: Context) {

    val settings: Flow<AppSettings> = context.dataStore.data.map { p ->
        AppSettings(
            intervalMinutes = p[Keys.IntervalMinutes] ?: 20,
            breakSeconds = p[Keys.BreakSeconds] ?: 20,
            snoozeMinutes = p[Keys.SnoozeMinutes] ?: 5,
            reminderStyle = p[Keys.ReminderStyle]
                ?.let { runCatching { ReminderStyle.valueOf(it) }.getOrNull() }
                ?: ReminderStyle.ALARM_SCREEN,
            soundMode = p[Keys.SoundMode]
                ?.let { runCatching { SoundMode.valueOf(it) }.getOrNull() }
                ?: SoundMode.SOFT,
            vibrationEnabled = p[Keys.VibrationEnabled] ?: true,
            onboardingDone = p[Keys.OnboardingDone] ?: false,
            dailyScheduleEnabled = p[Keys.DailyScheduleEnabled] ?: false,
            quietHoursEnabled = p[Keys.QuietHoursEnabled] ?: false,
            activeDaysMask = p[Keys.ActiveDaysMask] ?: 0b0111110,
            usageAwareEnabled = p[Keys.UsageAwareEnabled] ?: true,
            excludedPackages = p[Keys.ExcludedPackages]
                ?.split(",")
                ?.filter { it.isNotBlank() }
                ?.toSet()
                ?: emptySet(),
        )
    }

    val session: Flow<SessionState> = context.dataStore.data.map { p ->
        SessionState(
            protectionRunning = p[Keys.ProtectionRunning] ?: false,
            nextDueAtMillis = p[Keys.NextDueAt] ?: 0L,
            protectionStartedAtMillis = p[Keys.ProtectionStartedAt] ?: 0L,
            consecutiveMissed = p[Keys.ConsecutiveMissed] ?: 0,
            reminderOutstanding = p[Keys.ReminderOutstanding] ?: false,
        )
    }

    val stats: Flow<TodayStats> = context.dataStore.data.map { p ->
        val today = todayKey()
        val storedDate = p[Keys.StatsDate]
        if (storedDate != today) {
            TodayStats(date = today)
        } else {
            TodayStats(
                date = today,
                completed = p[Keys.StatsCompleted] ?: 0,
                skipped = p[Keys.StatsSkipped] ?: 0,
                missed = p[Keys.StatsMissed] ?: 0,
                protectedSeconds = p[Keys.StatsProtectedSec] ?: 0L,
            )
        }
    }

    suspend fun setInterval(minutes: Int) {
        context.dataStore.edit { it[Keys.IntervalMinutes] = minutes }
    }

    suspend fun setBreakSeconds(seconds: Int) {
        context.dataStore.edit { it[Keys.BreakSeconds] = seconds }
    }

    suspend fun setSnoozeMinutes(minutes: Int) {
        context.dataStore.edit { it[Keys.SnoozeMinutes] = minutes }
    }

    suspend fun setReminderStyle(style: ReminderStyle) {
        context.dataStore.edit { it[Keys.ReminderStyle] = style.name }
    }

    suspend fun setSoundMode(mode: SoundMode) {
        context.dataStore.edit { it[Keys.SoundMode] = mode.name }
    }

    suspend fun setVibration(enabled: Boolean) {
        context.dataStore.edit { it[Keys.VibrationEnabled] = enabled }
    }

    suspend fun setOnboardingDone(done: Boolean) {
        context.dataStore.edit { it[Keys.OnboardingDone] = done }
    }

    suspend fun setDailyScheduleEnabled(enabled: Boolean) {
        context.dataStore.edit { it[Keys.DailyScheduleEnabled] = enabled }
    }

    suspend fun setQuietHoursEnabled(enabled: Boolean) {
        context.dataStore.edit { it[Keys.QuietHoursEnabled] = enabled }
    }

    suspend fun setActiveDaysMask(mask: Int) {
        context.dataStore.edit { it[Keys.ActiveDaysMask] = mask }
    }

    suspend fun setUsageAwareEnabled(enabled: Boolean) {
        context.dataStore.edit { it[Keys.UsageAwareEnabled] = enabled }
    }

    suspend fun setExcludedPackages(packages: Set<String>) {
        context.dataStore.edit { it[Keys.ExcludedPackages] = packages.joinToString(",") }
    }

    suspend fun getAccumulatedScreenMs(): Long {
        return context.dataStore.data.first()[Keys.AccumulatedScreenMs] ?: 0L
    }

    suspend fun setAccumulatedScreenMs(ms: Long) {
        context.dataStore.edit { it[Keys.AccumulatedScreenMs] = ms }
    }

    suspend fun startProtection(nextDueAt: Long, now: Long) {
        context.dataStore.edit {
            it[Keys.ProtectionRunning] = true
            it[Keys.ProtectionStartedAt] = now
            it[Keys.NextDueAt] = nextDueAt
            it[Keys.ConsecutiveMissed] = 0
            it[Keys.ReminderOutstanding] = false
            it[Keys.AccumulatedScreenMs] = 0L
        }
    }

    suspend fun stopProtection(now: Long) {
        val started = context.dataStore.data.first()[Keys.ProtectionStartedAt] ?: 0L
        val protectedDeltaSec = if (started > 0) ((now - started) / 1000L).coerceAtLeast(0) else 0L
        context.dataStore.edit {
            it[Keys.ProtectionRunning] = false
            it[Keys.NextDueAt] = 0L
            it[Keys.ProtectionStartedAt] = 0L
            it[Keys.ReminderOutstanding] = false
            it[Keys.AccumulatedScreenMs] = 0L
            if (protectedDeltaSec > 0) {
                ensureStatsForToday(it)
                it[Keys.StatsProtectedSec] = (it[Keys.StatsProtectedSec] ?: 0L) + protectedDeltaSec
            }
        }
    }

    suspend fun setNextDueAt(time: Long) {
        context.dataStore.edit { it[Keys.NextDueAt] = time }
    }

    suspend fun markReminderShown() {
        context.dataStore.edit { it[Keys.ReminderOutstanding] = true }
    }

    suspend fun clearReminderOutstanding() {
        context.dataStore.edit { it[Keys.ReminderOutstanding] = false }
    }

    suspend fun bumpProtectedSeconds(seconds: Long) {
        if (seconds <= 0) return
        context.dataStore.edit {
            ensureStatsForToday(it)
            it[Keys.StatsProtectedSec] = (it[Keys.StatsProtectedSec] ?: 0L) + seconds
        }
    }

    suspend fun recordCompleted() {
        context.dataStore.edit {
            ensureStatsForToday(it)
            it[Keys.StatsCompleted] = (it[Keys.StatsCompleted] ?: 0) + 1
            it[Keys.ConsecutiveMissed] = 0
            it[Keys.ReminderOutstanding] = false
        }
    }

    suspend fun recordSkipped() {
        context.dataStore.edit {
            ensureStatsForToday(it)
            it[Keys.StatsSkipped] = (it[Keys.StatsSkipped] ?: 0) + 1
            it[Keys.ReminderOutstanding] = false
        }
    }

    suspend fun recordMissed() {
        context.dataStore.edit {
            ensureStatsForToday(it)
            it[Keys.StatsMissed] = (it[Keys.StatsMissed] ?: 0) + 1
            it[Keys.ConsecutiveMissed] = (it[Keys.ConsecutiveMissed] ?: 0) + 1
            it[Keys.ReminderOutstanding] = false
        }
    }

    suspend fun resetMissedStreak() {
        context.dataStore.edit { it[Keys.ConsecutiveMissed] = 0 }
    }

    suspend fun resetAccumulatedScreenMs() {
        context.dataStore.edit { it[Keys.AccumulatedScreenMs] = 0L }
    }

    suspend fun resetTodayStats() {
        context.dataStore.edit {
            it[Keys.StatsDate] = todayKey()
            it[Keys.StatsCompleted] = 0
            it[Keys.StatsSkipped] = 0
            it[Keys.StatsMissed] = 0
            it[Keys.StatsProtectedSec] = 0L
        }
    }

    private fun ensureStatsForToday(p: androidx.datastore.preferences.core.MutablePreferences) {
        val today = todayKey()
        if (p[Keys.StatsDate] != today) {
            p[Keys.StatsDate] = today
            p[Keys.StatsCompleted] = 0
            p[Keys.StatsSkipped] = 0
            p[Keys.StatsMissed] = 0
            p[Keys.StatsProtectedSec] = 0L
        }
    }

    private fun todayKey(): String =
        LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)

    companion object {
        @Volatile private var INSTANCE: PreferencesRepository? = null

        fun get(context: Context): PreferencesRepository =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: PreferencesRepository(context.applicationContext).also { INSTANCE = it }
            }
    }
}
