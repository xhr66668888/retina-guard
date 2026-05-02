package com.retinaguard.service

import android.annotation.SuppressLint
import android.Manifest
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.retinaguard.alarm.AlarmScheduler
import com.retinaguard.data.PreferencesRepository
import com.retinaguard.notification.NotificationHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class ProtectionService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var ticker: Job? = null
    private val prefs by lazy { PreferencesRepository.get(applicationContext) }
    private var usageTracker: ScreenUsageTracker? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        when (action) {
            ACTION_START -> handleStart()
            ACTION_REFRESH -> refresh()
            ACTION_STOP -> {
                handleStop()
                return START_NOT_STICKY
            }
        }
        return START_STICKY
    }

    private fun handleStart() {
        startForegroundCompat(NotificationHelper.buildOngoing(this, 0, paused = false))
        scope.launch {
            val s = prefs.settings.first()
            val now = System.currentTimeMillis()
            val due = now + s.intervalMinutes * 60_000L
            prefs.startProtection(nextDueAt = due, now = now)
            AlarmScheduler.schedule(applicationContext, due)
            startUsageTracker(s.excludedPackages)
            startTicker()
        }
    }

    private fun refresh() {
        startForegroundCompat(NotificationHelper.buildOngoing(this, 0, paused = false))
        scope.launch {
            val session = prefs.session.first()
            if (!session.protectionRunning) {
                handleStop()
                return@launch
            }
            val s = prefs.settings.first()
            AlarmScheduler.schedule(applicationContext, session.nextDueAtMillis)
            startUsageTracker(s.excludedPackages)
            startTicker()
        }
    }

    private fun handleStop() {
        startForegroundCompat(NotificationHelper.buildOngoing(this, 0, paused = true))
        ticker?.cancel()
        ticker = null
        val tracker = usageTracker
        if (tracker != null) {
            val accumulated = tracker.stop()
            usageTracker = null
            scope.launch {
                prefs.setAccumulatedScreenMs(accumulated)
                prefs.stopProtection(System.currentTimeMillis())
                ServiceCompat.stopForeground(this@ProtectionService, ServiceCompat.STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        } else {
            scope.launch {
                prefs.stopProtection(System.currentTimeMillis())
                ServiceCompat.stopForeground(this@ProtectionService, ServiceCompat.STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
    }

    private suspend fun startUsageTracker(excludedPackages: Set<String>) {
        if (usageTracker != null) return
        val s = prefs.settings.first()
        if (!s.usageAwareEnabled) return
        val accumulated = prefs.getAccumulatedScreenMs()
        val tracker = ScreenUsageTracker(applicationContext)
        tracker.start(accumulated, excludedPackages)
        usageTracker = tracker
    }

    @SuppressLint("MissingPermission")
    private fun startTicker() {
        ticker?.cancel()
        ticker = scope.launch {
            val nm = NotificationManagerCompat.from(applicationContext)
            var persistCounter = 0
            while (true) {
                val session = prefs.session.first()
                if (!session.protectionRunning) break

                val settings = prefs.settings.first()
                val tracker = usageTracker
                val useUsageAware = settings.usageAwareEnabled && tracker != null

                if (useUsageAware) {
                    tracker!!.tick()
                    val accumulatedMs = tracker.getAccumulatedMs()
                    val intervalMs = settings.intervalMinutes * 60_000L
                    val remainingMs = intervalMs - accumulatedMs
                    val remainingSec = (remainingMs / 1000L).coerceAtLeast(0L)

                    if (canPostNotifications()) runCatching {
                        nm.notify(
                            NotificationHelper.NOTIF_ONGOING,
                            NotificationHelper.buildOngoing(applicationContext, remainingSec, paused = false)
                        )
                    }

                    if (remainingMs <= 0) {
                        prefs.resetAccumulatedScreenMs()
                        triggerBreak()
                        delay(2_000L)
                        continue
                    }

                    persistCounter++
                    if (persistCounter >= 30) {
                        prefs.setAccumulatedScreenMs(accumulatedMs)
                        persistCounter = 0
                    }
                } else {
                    val now = System.currentTimeMillis()
                    val remainingMs = session.nextDueAtMillis - now
                    val remainingSec = (remainingMs / 1000L).coerceAtLeast(0L)

                    if (canPostNotifications()) runCatching {
                        nm.notify(
                            NotificationHelper.NOTIF_ONGOING,
                            NotificationHelper.buildOngoing(applicationContext, remainingSec, paused = false)
                        )
                    }

                    if (remainingSec <= 0) {
                        delay(2_000L)
                        continue
                    }
                }
                delay(1_000L)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun triggerBreak() {
        val settings = prefs.settings.first()
        prefs.markReminderShown()
        if (canPostNotifications()) {
            val nm = NotificationManagerCompat.from(applicationContext)
            nm.notify(
                NotificationHelper.NOTIF_BREAK,
                NotificationHelper.buildBreakReminder(applicationContext, settings, false)
            )
        }
        val nextDue = System.currentTimeMillis() + settings.intervalMinutes * 60_000L
        prefs.setNextDueAt(nextDue)
        AlarmScheduler.schedule(applicationContext, nextDue)
    }

    private fun startForegroundCompat(notification: android.app.Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                NotificationHelper.NOTIF_ONGOING,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NotificationHelper.NOTIF_ONGOING, notification)
        }
    }

    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onDestroy() {
        super.onDestroy()
        ticker?.cancel()
        usageTracker?.stop()
        usageTracker = null
        scope.cancel()
    }

    companion object {
        const val ACTION_START = "com.retinaguard.service.START"
        const val ACTION_STOP = "com.retinaguard.service.STOP"
        const val ACTION_REFRESH = "com.retinaguard.service.REFRESH"

        fun start(context: Context) {
            val intent = Intent(context, ProtectionService::class.java).setAction(ACTION_START)
            startForegroundCompat(context, intent)
        }

        fun stop(context: Context) {
            val intent = Intent(context, ProtectionService::class.java).setAction(ACTION_STOP)
            startForegroundCompat(context, intent)
        }

        fun refresh(context: Context) {
            val intent = Intent(context, ProtectionService::class.java).setAction(ACTION_REFRESH)
            startForegroundCompat(context, intent)
        }

        private fun startForegroundCompat(context: Context, intent: Intent) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
