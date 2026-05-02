package com.retinaguard.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.retinaguard.permission.PermissionLaunchers
import com.retinaguard.permission.PermissionsState
import com.retinaguard.ui.components.ChecklistRow
import com.retinaguard.ui.components.GhostRectangleButton
import com.retinaguard.ui.components.RedBand
import com.retinaguard.ui.components.RedPillButton
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed

@Composable
fun OnboardingScreen(
    permissions: PermissionsState,
    onRefresh: () -> Unit,
    onFinish: () -> Unit,
) {
    val ctx = LocalContext.current

    val notifLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { _ -> onRefresh() }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 96.dp),
        ) {
            Spacer(Modifier.height(24.dp))
            Text(
                "RETINA GUARD",
                color = Charcoal,
                fontWeight = FontWeight.W800,
                fontSize = 14.sp,
                modifier = Modifier.padding(horizontal = 24.dp),
            )
            Spacer(Modifier.height(48.dp))
            Text(
                "PROTECT\nYOUR EYES",
                color = Charcoal,
                fontWeight = FontWeight.W800,
                fontSize = 56.sp,
                lineHeight = 56.sp,
                modifier = Modifier.padding(horizontal = 24.dp),
                textAlign = TextAlign.Start,
            )
            Spacer(Modifier.height(20.dp))
            Text(
                "Every 20 minutes, take 20 seconds to look into the distance.",
                color = SecondaryGrey,
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.padding(horizontal = 24.dp),
            )

            Spacer(Modifier.height(40.dp))
            RedBand()
            Spacer(Modifier.height(32.dp))

            Text(
                "Reliability checklist",
                color = Charcoal,
                style = MaterialTheme.typography.headlineMedium,
                modifier = Modifier.padding(horizontal = 24.dp),
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "Retina Guard works best when it can behave like a clock alarm. " +
                    "Notifications and exact alarms are required; the rest improve reliability.",
                color = SecondaryGrey,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(horizontal = 24.dp),
            )

            Spacer(Modifier.height(16.dp))

            ChecklistRow(
                title = "Notifications",
                description = "Required to deliver break reminders.",
                granted = permissions.notifications,
                actionLabel = "Allow",
                onAction = {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    } else {
                        PermissionLaunchers.openAppNotificationSettings(ctx)
                    }
                },
            )
            ChecklistRow(
                title = "Exact alarms",
                description = "Lets the next break fire on time even in standby.",
                granted = permissions.exactAlarms,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openExactAlarmSettings(ctx) },
            )
            ChecklistRow(
                title = "Full-screen alarm",
                description = "Show a break alarm screen over the lock screen.",
                granted = permissions.fullScreenAlarm,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openFullScreenIntentSettings(ctx) },
            )
            ChecklistRow(
                title = "Battery unrestricted",
                description = "Stops the OS from killing the countdown service.",
                granted = permissions.batteryUnrestricted,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openBatteryOptimizationSettings(ctx) },
            )
            ChecklistRow(
                title = "DND bypass",
                description = "Lets alarms break through Do Not Disturb.",
                granted = permissions.dndPolicy,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openDndAccessSettings(ctx) },
            )
            ChecklistRow(
                title = "Overlay nudge",
                description = "Show a small reminder over other apps.",
                granted = permissions.overlay,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openOverlaySettings(ctx) },
            )
            ChecklistRow(
                title = "Usage Access",
                description = "Required for usage-aware reminders.",
                granted = permissions.usageAccess,
                actionLabel = "Open",
                onAction = { PermissionLaunchers.openUsageAccessSettings(ctx) },
            )

            Spacer(Modifier.height(96.dp))
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            val enough = permissions.readyForBasic
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                GhostRectangleButton(
                    text = "Skip for now",
                    onClick = onFinish,
                    modifier = Modifier.weight(1f),
                )
                RedPillButton(
                    text = if (enough) "Continue" else "${permissions.readyCount}/${permissions.totalCount} ready",
                    onClick = onFinish,
                    enabled = enough,
                    modifier = Modifier.weight(1f),
                )
            }
            if (!enough) {
                Text(
                    text = "Notifications and exact alarms are required to start.",
                    color = VodafoneRed,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}
