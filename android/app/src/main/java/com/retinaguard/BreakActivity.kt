package com.retinaguard

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.viewmodel.compose.viewModel
import com.retinaguard.receiver.ActionReceiver
import com.retinaguard.ui.MainViewModel
import com.retinaguard.ui.breakflow.BreakScreen
import com.retinaguard.ui.theme.RetinaGuardTheme

class BreakActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowOverLockscreen()
        setContent {
            RetinaGuardTheme(darkSurface = true) {
                val vm: MainViewModel = viewModel()
                val settings by vm.settings.collectAsState()
                BreakScreen(
                    breakSeconds = settings.breakSeconds,
                    snoozeMinutes = settings.snoozeMinutes,
                    onComplete = {
                        sendAction(ActionReceiver.ACTION_COMPLETE)
                        finishAndRemoveTask()
                    },
                    onSnooze = {
                        sendAction(ActionReceiver.ACTION_SNOOZE)
                        finishAndRemoveTask()
                    },
                    onSkip = {
                        sendAction(ActionReceiver.ACTION_SKIP)
                        finishAndRemoveTask()
                    },
                )
            }
        }
    }

    private fun sendAction(action: String) {
        sendBroadcast(Intent(this, ActionReceiver::class.java).setAction(action))
    }

    private fun setShowOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    companion object {
        fun startIntent(context: Context): Intent =
            Intent(context, BreakActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }
}
