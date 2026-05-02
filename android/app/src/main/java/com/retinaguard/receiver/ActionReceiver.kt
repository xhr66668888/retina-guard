package com.retinaguard.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.retinaguard.alarm.AlarmScheduler
import com.retinaguard.data.PreferencesRepository
import com.retinaguard.notification.NotificationHelper
import com.retinaguard.service.OverlayReminderService
import com.retinaguard.service.ProtectionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class ActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        val action = intent.action ?: return
        val pendingResult = goAsync()

        CoroutineScope(Dispatchers.Default).launch {
            try {
                val prefs = PreferencesRepository.get(app)
                val nm = NotificationManagerCompat.from(app)
                OverlayReminderService.hide(app)
                when (action) {
                    ACTION_STOP -> {
                        ProtectionService.stop(app)
                        nm.cancel(NotificationHelper.NOTIF_BREAK)
                    }
                    ACTION_SNOOZE -> {
                        nm.cancel(NotificationHelper.NOTIF_BREAK)
                        prefs.clearReminderOutstanding()
                        prefs.resetAccumulatedScreenMs()
                        val s = prefs.settings.first()
                        val due = System.currentTimeMillis() + s.snoozeMinutes * 60_000L
                        prefs.setNextDueAt(due)
                        AlarmScheduler.schedule(app, due)
                    }
                    ACTION_SKIP -> {
                        nm.cancel(NotificationHelper.NOTIF_BREAK)
                        prefs.recordSkipped()
                        prefs.resetAccumulatedScreenMs()
                        val s = prefs.settings.first()
                        val due = System.currentTimeMillis() + s.intervalMinutes * 60_000L
                        prefs.setNextDueAt(due)
                        AlarmScheduler.schedule(app, due)
                    }
                    ACTION_COMPLETE -> {
                        nm.cancel(NotificationHelper.NOTIF_BREAK)
                        prefs.recordCompleted()
                        prefs.resetAccumulatedScreenMs()
                        val s = prefs.settings.first()
                        val due = System.currentTimeMillis() + s.intervalMinutes * 60_000L
                        prefs.setNextDueAt(due)
                        AlarmScheduler.schedule(app, due)
                    }
                    ACTION_MISSED -> {
                        prefs.recordMissed()
                    }
                }
            } finally {
                pendingResult.finish()
            }
        }
    }

    companion object {
        const val ACTION_STOP = "com.retinaguard.action.STOP"
        const val ACTION_SNOOZE = "com.retinaguard.action.SNOOZE"
        const val ACTION_SKIP = "com.retinaguard.action.SKIP"
        const val ACTION_COMPLETE = "com.retinaguard.action.COMPLETE"
        const val ACTION_MISSED = "com.retinaguard.action.MISSED"
    }
}
