package com.retinaguard.permission

import android.Manifest
import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import androidx.core.content.ContextCompat

data class PermissionsState(
    val notifications: Boolean,
    val exactAlarms: Boolean,
    val fullScreenAlarm: Boolean,
    val batteryUnrestricted: Boolean,
    val dndPolicy: Boolean,
    val overlay: Boolean,
    val usageAccess: Boolean,
) {
    val readyForBasic: Boolean get() = notifications && exactAlarms
    val readyCount: Int
        get() = listOf(
            notifications, exactAlarms, fullScreenAlarm,
            batteryUnrestricted, dndPolicy, overlay, usageAccess
        ).count { it }
    val totalCount: Int = 7

    companion object {
        fun read(context: Context): PermissionsState = PermissionsState(
            notifications = hasNotifications(context),
            exactAlarms = hasExactAlarm(context),
            fullScreenAlarm = hasFullScreenIntent(context),
            batteryUnrestricted = isBatteryUnrestricted(context),
            dndPolicy = hasDndAccess(context),
            overlay = canDrawOverlays(context),
            usageAccess = hasUsageAccess(context),
        )

        private fun hasNotifications(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.checkSelfPermission(
                    context, Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            } else true
        }

        private fun hasExactAlarm(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            return am.canScheduleExactAlarms()
        }

        private fun hasFullScreenIntent(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
            val nm = context.getSystemService(NotificationManager::class.java) ?: return false
            return nm.canUseFullScreenIntent()
        }

        private fun isBatteryUnrestricted(context: Context): Boolean {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(context.packageName)
        }

        private fun hasDndAccess(context: Context): Boolean {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return false
            return nm.isNotificationPolicyAccessGranted
        }

        private fun canDrawOverlays(context: Context): Boolean =
            Settings.canDrawOverlays(context)

        private fun hasUsageAccess(context: Context): Boolean {
            val ops = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
                ?: return false
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ops.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                ops.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            }
            return mode == AppOpsManager.MODE_ALLOWED
        }
    }
}
