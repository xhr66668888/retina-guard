package com.retinaguard.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.retinaguard.alarm.AlarmScheduler
import com.retinaguard.data.PreferencesRepository
import com.retinaguard.service.ProtectionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action !in HANDLED) return

        val app = context.applicationContext
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                val prefs = PreferencesRepository.get(app)
                val session = prefs.session.first()
                if (!session.protectionRunning) return@launch

                val settings = prefs.settings.first()
                val now = System.currentTimeMillis()
                // If the recorded due time is in the past (likely after a reboot),
                // pick the next interval boundary from now.
                val due = if (session.nextDueAtMillis > now) {
                    session.nextDueAtMillis
                } else {
                    now + settings.intervalMinutes * 60_000L
                }
                prefs.setNextDueAt(due)
                AlarmScheduler.schedule(app, due)
                ProtectionService.refresh(app)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private companion object {
        val HANDLED = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
        )
    }
}
