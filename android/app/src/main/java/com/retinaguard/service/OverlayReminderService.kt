package com.retinaguard.service

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import com.retinaguard.BreakActivity
import com.retinaguard.R
import com.retinaguard.notification.NotificationHelper
import com.retinaguard.receiver.ActionReceiver

class OverlayReminderService : Service() {

    private var overlayView: View? = null
    private val wm by lazy { getSystemService(WINDOW_SERVICE) as WindowManager }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundCompat()
        if (!Settings.canDrawOverlays(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        showOverlay()
        return START_STICKY
    }

    private fun showOverlay() {
        if (overlayView != null) return

        val brandRed = getColorCompat(R.color.brand_red)
        val charcoal = getColorCompat(R.color.charcoal)
        val secondary = getColorCompat(R.color.secondary_grey)

        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 22, 28, 22)
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = 12f
                setStroke(3, brandRed)
            }
            elevation = 12f
        }

        panel.addView(TextView(this).apply {
            text = "TIME TO LOOK AWAY"
            setTextColor(charcoal)
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
        })
        panel.addView(TextView(this).apply {
            text = "Focus on something far away for 20 seconds."
            setTextColor(secondary)
            textSize = 14f
            setPadding(0, 8, 0, 16)
        })

        val buttons = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        buttons.addView(actionButton("Start break", brandRed, Color.WHITE) {
            startActivity(BreakActivity.startIntent(this))
            dismissOverlay()
        })
        buttons.addView(actionButton("Snooze", Color.WHITE, charcoal) {
            sendAction(ActionReceiver.ACTION_SNOOZE)
            dismissOverlay()
        })
        buttons.addView(actionButton("Skip", Color.WHITE, charcoal) {
            sendAction(ActionReceiver.ACTION_SKIP)
            dismissOverlay()
        })
        panel.addView(buttons)

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = 96
        }

        overlayView = panel
        wm.addView(panel, lp)
    }

    private fun actionButton(
        textValue: String,
        bg: Int,
        fg: Int,
        onClick: () -> Unit
    ): Button = Button(this).apply {
        text = textValue
        setTextColor(fg)
        textSize = 12f
        isAllCaps = false
        background = GradientDrawable().apply {
            setColor(bg)
            cornerRadius = 4f
            setStroke(2, getColorCompat(R.color.charcoal))
        }
        setOnClickListener { onClick() }
    }

    private fun sendAction(action: String) {
        sendBroadcast(Intent(this, ActionReceiver::class.java).setAction(action))
    }

    private fun dismissOverlay() {
        stopSelf()
    }

    private fun startForegroundCompat() {
        val notification = NotificationHelper.buildOverlayServiceNotification(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                NotificationHelper.NOTIF_OVERLAY,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NotificationHelper.NOTIF_OVERLAY, notification)
        }
    }

    override fun onDestroy() {
        overlayView?.let { runCatching { wm.removeView(it) } }
        overlayView = null
        NotificationManagerCompat.from(this).cancel(NotificationHelper.NOTIF_OVERLAY)
        super.onDestroy()
    }

    private fun getColorCompat(id: Int): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) getColor(id)
        else @Suppress("DEPRECATION") resources.getColor(id)

    companion object {
        fun show(context: Context) {
            val intent = Intent(context, OverlayReminderService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun hide(context: Context) {
            context.stopService(Intent(context, OverlayReminderService::class.java))
        }
    }
}
