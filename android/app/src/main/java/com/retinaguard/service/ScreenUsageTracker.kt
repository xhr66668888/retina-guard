package com.retinaguard.service

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class ScreenUsageTracker(private val context: Context) {

    private val _screenOn = MutableStateFlow(isScreenOn())
    val screenOn: StateFlow<Boolean> = _screenOn.asStateFlow()

    private var accumulatedMs: Long = 0L
    private var lastResumeTime: Long = 0L
    private var excludedPackages: Set<String> = emptySet()
    private var isPausedForExcluded = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> {
                    _screenOn.value = true
                    lastResumeTime = System.currentTimeMillis()
                    isPausedForExcluded = false
                }
                Intent.ACTION_SCREEN_OFF -> {
                    _screenOn.value = false
                    flush()
                }
            }
        }
    }

    fun start(initialAccumulatedMs: Long = 0L, excluded: Set<String> = emptySet()) {
        accumulatedMs = initialAccumulatedMs
        excludedPackages = excluded
        lastResumeTime = if (isScreenOn()) System.currentTimeMillis() else 0L
        isPausedForExcluded = false
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(screenReceiver, filter)
        }
    }

    fun stop(): Long {
        flush()
        try { context.unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        return accumulatedMs
    }

    fun updateExcludedPackages(excluded: Set<String>) {
        excludedPackages = excluded
    }

    fun getAccumulatedMs(): Long {
        flush()
        return accumulatedMs
    }

    fun isExcludedAppInForeground(): Boolean {
        if (excludedPackages.isEmpty()) return false
        val currentPkg = getForegroundPackage() ?: return false
        return currentPkg in excludedPackages
    }

    fun tick() {
        if (!_screenOn.value) return
        val now = System.currentTimeMillis()
        val excluded = isExcludedAppInForeground()
        if (excluded) {
            if (!isPausedForExcluded) {
                flush()
                isPausedForExcluded = true
            }
        } else {
            if (isPausedForExcluded) {
                lastResumeTime = now
                isPausedForExcluded = false
            }
            if (lastResumeTime == 0L) lastResumeTime = now
            accumulatedMs += (now - lastResumeTime)
            lastResumeTime = now
        }
    }

    private fun flush() {
        if (!_screenOn.value || lastResumeTime == 0L) return
        val now = System.currentTimeMillis()
        if (!isPausedForExcluded) {
            accumulatedMs += (now - lastResumeTime)
        }
        lastResumeTime = now
    }

    private fun isScreenOn(): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isInteractive
    }

    private fun getForegroundPackage(): String? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 10_000L, now) ?: return null
        var lastPkg: String? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            @Suppress("DEPRECATION")
            val isForeground = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    event.eventType == UsageEvents.Event.ACTIVITY_PAUSED
            } else {
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                    event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND
            }
            if (isForeground) {
                lastPkg = event.packageName
            }
        }
        return lastPkg
    }
}
