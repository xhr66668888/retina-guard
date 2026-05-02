package com.retinaguard

import android.app.Application
import com.retinaguard.notification.NotificationHelper

class RetinaGuardApp : Application() {
    override fun onCreate() {
        super.onCreate()
        NotificationHelper.ensureChannels(this)
    }
}
