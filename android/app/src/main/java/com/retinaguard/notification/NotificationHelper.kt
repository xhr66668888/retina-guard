package com.retinaguard.notification

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.retinaguard.BreakActivity
import com.retinaguard.MainActivity
import com.retinaguard.R
import com.retinaguard.data.AppSettings
import com.retinaguard.data.SoundMode
import com.retinaguard.receiver.ActionReceiver

object NotificationHelper {

    const val CHANNEL_ONGOING = "protection_ongoing"
    private const val CHANNEL_BREAK_PREFIX = "eye_break_alarm"
    const val CHANNEL_OVERLAY = "overlay_reminder"

    const val NOTIF_ONGOING = 1001
    const val NOTIF_BREAK = 1002
    const val NOTIF_OVERLAY = 1003

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return

        if (nm.getNotificationChannel(CHANNEL_ONGOING) == null) {
            val ongoing = NotificationChannel(
                CHANNEL_ONGOING,
                "Protection running",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Live countdown to your next eye break."
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            nm.createNotificationChannel(ongoing)
        }

        listOf(SoundMode.OFF, SoundMode.SOFT, SoundMode.ALARM).forEach { sound ->
            listOf(false, true).forEach { vibrate ->
                val id = breakChannelId(sound, vibrate)
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                val ch = NotificationChannel(
                    id,
                    breakChannelName(sound, vibrate),
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Reminds you to look 20 feet away for 20 seconds."
                    setBypassDnd(hasDndPolicyAccess(context))
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    enableVibration(vibrate)
                    vibrationPattern = if (vibrate) longArrayOf(0, 250, 200, 250) else longArrayOf(0)
                    val soundUri = when (sound) {
                        SoundMode.OFF -> null
                        SoundMode.SOFT -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        SoundMode.ALARM -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    }
                    setSound(soundUri, if (soundUri == null) null else attrs)
                }
                nm.createNotificationChannel(ch)
            }
        }

        if (nm.getNotificationChannel(CHANNEL_OVERLAY) == null) {
            val overlay = NotificationChannel(
                CHANNEL_OVERLAY,
                "Overlay reminder",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the overlay eye-break reminder running."
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            nm.createNotificationChannel(overlay)
        }
    }

    fun buildOngoing(context: Context, remainingSeconds: Long, paused: Boolean): Notification {
        val mins = (remainingSeconds / 60).coerceAtLeast(0)
        val secs = (remainingSeconds % 60).coerceAtLeast(0)
        val title = if (paused) {
            "Protection paused"
        } else {
            "Next break in %02d:%02d".format(mins, secs)
        }

        val openApp = PendingIntent.getActivity(
            context,
            10,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = PendingIntent.getBroadcast(
            context,
            11,
            Intent(context, ActionReceiver::class.java).setAction(ActionReceiver.ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val takeBreakIntent = PendingIntent.getActivity(
            context,
            12,
            BreakActivity.startIntent(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(context, CHANNEL_ONGOING)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.brand_red))
            .setColorized(false)
            .setContentTitle(title)
            .setContentText(if (paused) "Tap to resume" else "Retina Guard is running")
            .setContentIntent(openApp)
            .setOngoing(true)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(0, "Take break", takeBreakIntent)
            .addAction(0, "Stop", stopIntent)
            .build()
    }

    fun buildBreakReminder(
        context: Context,
        settings: AppSettings,
        useFullScreen: Boolean
    ): Notification {
        val openBreak = PendingIntent.getActivity(
            context,
            20,
            BreakActivity.startIntent(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val snooze = PendingIntent.getBroadcast(
            context,
            21,
            Intent(context, ActionReceiver::class.java).setAction(ActionReceiver.ACTION_SNOOZE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val skip = PendingIntent.getBroadcast(
            context,
            22,
            Intent(context, ActionReceiver::class.java).setAction(ActionReceiver.ACTION_SKIP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val missed = PendingIntent.getBroadcast(
            context,
            23,
            Intent(context, ActionReceiver::class.java).setAction(ActionReceiver.ACTION_MISSED),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(
            context,
            breakChannelId(settings.soundMode, settings.vibrationEnabled)
        )
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.brand_red))
            .setContentTitle("Time to look away")
            .setContentText("Focus on something far away for 20 seconds.")
            .setContentIntent(openBreak)
            .setDeleteIntent(missed)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, "Start break", openBreak)
            .addAction(0, "Snooze 5m", snooze)
            .addAction(0, "Skip", skip)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            when (settings.soundMode) {
                SoundMode.OFF -> builder.setSound(null)
                SoundMode.SOFT -> builder.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                SoundMode.ALARM -> builder.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
            }
            if (settings.vibrationEnabled) {
                builder.setVibrate(longArrayOf(0, 250, 200, 250))
            } else {
                builder.setVibrate(longArrayOf(0))
            }
        }

        if (useFullScreen) {
            builder.setFullScreenIntent(openBreak, true)
        }

        return builder.build()
    }

    fun buildOverlayServiceNotification(context: Context): Notification {
        val openBreak = PendingIntent.getActivity(
            context,
            30,
            BreakActivity.startIntent(context).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(context, CHANNEL_OVERLAY)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.brand_red))
            .setContentTitle("Eye break reminder")
            .setContentText("Overlay nudge is visible")
            .setContentIntent(openBreak)
            .setOngoing(true)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun breakChannelId(soundMode: SoundMode, vibrationEnabled: Boolean): String {
        val sound = soundMode.name.lowercase()
        val vibration = if (vibrationEnabled) "vibrate" else "silent"
        return "${CHANNEL_BREAK_PREFIX}_${sound}_$vibration"
    }

    private fun breakChannelName(soundMode: SoundMode, vibrationEnabled: Boolean): String {
        val sound = when (soundMode) {
            SoundMode.OFF -> "silent"
            SoundMode.SOFT -> "soft"
            SoundMode.ALARM -> "alarm"
        }
        val vibration = if (vibrationEnabled) "with vibration" else "no vibration"
        return "Eye break reminder ($sound, $vibration)"
    }

    private fun hasDndPolicyAccess(context: Context): Boolean {
        val nm = context.getSystemService(NotificationManager::class.java) ?: return false
        return nm.isNotificationPolicyAccessGranted
    }
}
