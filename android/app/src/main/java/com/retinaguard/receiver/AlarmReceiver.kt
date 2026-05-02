package com.retinaguard.receiver

import android.annotation.SuppressLint
import android.Manifest
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.retinaguard.alarm.AlarmScheduler
import com.retinaguard.data.PreferencesRepository
import com.retinaguard.data.ReminderStyle
import com.retinaguard.notification.NotificationHelper
import com.retinaguard.service.OverlayReminderService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Calendar

/**
 * Fired by AlarmManager when the next break is due. The alarm
 * is the source of truth for due time; this receiver posts the high-importance
 * break reminder, escalates if recently missed, and schedules the next cycle.
 */
class AlarmReceiver : BroadcastReceiver() {

    @SuppressLint("MissingPermission")
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != AlarmScheduler.ACTION_REMINDER) return

        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wl = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "retinaguard:alarm"
        )
        wl.acquire(15_000L)

        val pendingResult = goAsync()
        val app = context.applicationContext
        CoroutineScope(Dispatchers.Default).launch {
            try {
                val prefs = PreferencesRepository.get(app)
                val settings = prefs.settings.first()
                val session = prefs.session.first()

                if (!session.protectionRunning) {
                    return@launch
                }

                if (session.reminderOutstanding) {
                    prefs.recordMissed()
                }

                val now = System.currentTimeMillis()
                val deferredUntil = nextAllowedReminderTime(settings, now)
                if (deferredUntil != null) {
                    prefs.setNextDueAt(deferredUntil)
                    AlarmScheduler.schedule(app, deferredUntil)
                    return@launch
                }

                NotificationHelper.ensureChannels(app)

                // Determine effective reminder style with simple escalation:
                // 3 misses in a row -> upgrade Heads-up to Alarm screen.
                val effectiveStyle = when {
                    session.consecutiveMissed >= 3 &&
                        settings.reminderStyle == ReminderStyle.HEADS_UP -> ReminderStyle.ALARM_SCREEN
                    else -> settings.reminderStyle
                }

                val useOverlay = effectiveStyle == ReminderStyle.OVERLAY && Settings.canDrawOverlays(app)
                val useFullScreen = (effectiveStyle == ReminderStyle.ALARM_SCREEN ||
                    effectiveStyle == ReminderStyle.OVERLAY) &&
                    !useOverlay &&
                    canUseFullScreenIntent(app)

                prefs.markReminderShown()

                if (useOverlay) {
                    OverlayReminderService.show(app)
                }

                if (canPostNotifications(app)) {
                    NotificationManagerCompat.from(app).notify(
                        NotificationHelper.NOTIF_BREAK,
                        NotificationHelper.buildBreakReminder(app, settings, useFullScreen)
                    )
                }

                // Schedule the next reminder so the cycle keeps going even if user ignores.
                val nextDue = System.currentTimeMillis() + settings.intervalMinutes * 60_000L
                prefs.setNextDueAt(nextDue)
                prefs.resetAccumulatedScreenMs()
                AlarmScheduler.schedule(app, nextDue)
            } finally {
                if (wl.isHeld) wl.release()
                pendingResult.finish()
            }
        }
    }

    private fun canUseFullScreenIntent(context: Context): Boolean {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val nm = context.getSystemService(NotificationManager::class.java) ?: return false
        return nm.canUseFullScreenIntent()
    }

    private fun canPostNotifications(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun nextAllowedReminderTime(
        settings: com.retinaguard.data.AppSettings,
        now: Long
    ): Long? {
        val candidates = mutableListOf<Long>()
        if (settings.quietHoursEnabled) {
            nextQuietHoursEnd(now)?.let { candidates += it }
        }
        if (settings.dailyScheduleEnabled) {
            nextDailyWindowStart(settings.activeDaysMask, now)?.let { candidates += it }
        }
        return candidates.maxOrNull()
    }

    private fun nextQuietHoursEnd(now: Long): Long? {
        val cal = Calendar.getInstance().apply { timeInMillis = now }
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        if (hour in 8 until 22) return null
        if (hour >= 22) cal.add(Calendar.DAY_OF_YEAR, 1)
        cal.set(Calendar.HOUR_OF_DAY, 8)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun nextDailyWindowStart(mask: Int, now: Long): Long? {
        val cal = Calendar.getInstance().apply { timeInMillis = now }
        val dayIndex = cal.get(Calendar.DAY_OF_WEEK) - 1
        val minutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        val start = 9 * 60
        val end = 18 * 60
        val activeToday = mask and (1 shl dayIndex) != 0
        if (activeToday && minutes in start until end) return null

        val search = Calendar.getInstance().apply { timeInMillis = now }
        repeat(8) { offset ->
            val idx = search.get(Calendar.DAY_OF_WEEK) - 1
            val active = mask and (1 shl idx) != 0
            if (active && (offset > 0 || minutes < start || !activeToday)) {
                search.set(Calendar.HOUR_OF_DAY, 9)
                search.set(Calendar.MINUTE, 0)
                search.set(Calendar.SECOND, 0)
                search.set(Calendar.MILLISECOND, 0)
                if (search.timeInMillis > now) return search.timeInMillis
            }
            search.add(Calendar.DAY_OF_YEAR, 1)
        }
        return null
    }
}
