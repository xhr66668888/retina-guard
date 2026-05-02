package com.retinaguard.data

enum class ReminderStyle { HEADS_UP, ALARM_SCREEN, OVERLAY }

enum class SoundMode { OFF, SOFT, ALARM }

data class AppSettings(
    val intervalMinutes: Int = 20,
    val breakSeconds: Int = 20,
    val snoozeMinutes: Int = 5,
    val reminderStyle: ReminderStyle = ReminderStyle.ALARM_SCREEN,
    val soundMode: SoundMode = SoundMode.SOFT,
    val vibrationEnabled: Boolean = true,
    val onboardingDone: Boolean = false,
    val dailyScheduleEnabled: Boolean = false,
    val quietHoursEnabled: Boolean = false,
    val activeDaysMask: Int = 0b0111110,
    val usageAwareEnabled: Boolean = true,
    val excludedPackages: Set<String> = emptySet(),
)

data class SessionState(
    val protectionRunning: Boolean = false,
    val nextDueAtMillis: Long = 0L,
    val protectionStartedAtMillis: Long = 0L,
    val consecutiveMissed: Int = 0,
    val reminderOutstanding: Boolean = false,
)

data class TodayStats(
    val date: String = "",
    val completed: Int = 0,
    val skipped: Int = 0,
    val missed: Int = 0,
    val protectedSeconds: Long = 0L,
)

val IntervalChoices = listOf(5, 10, 15, 20, 30, 45, 60)
