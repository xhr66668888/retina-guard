package com.retinaguard.ui.settings

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.graphics.drawable.toBitmap
import com.retinaguard.data.AppSettings
import com.retinaguard.data.ReminderStyle
import com.retinaguard.data.SoundMode
import com.retinaguard.permission.PermissionLaunchers
import com.retinaguard.permission.PermissionsState
import com.retinaguard.ui.components.ChecklistRow
import com.retinaguard.ui.components.RedBand
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.LightNeutral
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed

@Composable
fun SettingsScreen(
    settings: AppSettings,
    permissions: PermissionsState,
    onReminderStyleChange: (ReminderStyle) -> Unit,
    onSoundModeChange: (SoundMode) -> Unit,
    onVibrationChange: (Boolean) -> Unit,
    onUsageAwareChange: (Boolean) -> Unit,
    onExcludedPackagesChange: (Set<String>) -> Unit,
    onResetStats: () -> Unit,
    contentPadding: PaddingValues,
) {
    val ctx = LocalContext.current
    var showAppPicker by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(contentPadding)
            .verticalScroll(rememberScrollState()),
    ) {
        Spacer(Modifier.height(12.dp))
        Text(
            "SETTINGS",
            style = MaterialTheme.typography.labelLarge,
            color = Charcoal,
            modifier = Modifier.padding(horizontal = 24.dp),
        )

        Spacer(Modifier.height(24.dp))
        SectionHeading("Reliability")
        Spacer(Modifier.height(8.dp))
        PermissionList(permissions = permissions, ctx = ctx)

        RedBand()

        Spacer(Modifier.height(24.dp))
        SectionHeading("Usage-aware mode")
        Spacer(Modifier.height(8.dp))
        ToggleRow(
            label = "Screen-time tracking",
            description = "Count only actual screen-on time toward breaks.",
            checked = settings.usageAwareEnabled,
            onCheckedChange = onUsageAwareChange,
        )
        if (settings.usageAwareEnabled) {
            ExclusionListRow(
                excludedPackages = settings.excludedPackages,
                onManage = { showAppPicker = true },
            )
        }

        RedBand()

        Spacer(Modifier.height(24.dp))
        SectionHeading("Reminder")
        Spacer(Modifier.height(8.dp))
        SegmentedRow(
            label = "Style",
            options = listOf(
                ReminderStyle.HEADS_UP to "Heads-up",
                ReminderStyle.ALARM_SCREEN to "Alarm screen",
                ReminderStyle.OVERLAY to "Overlay",
            ),
            current = settings.reminderStyle,
            onSelect = onReminderStyleChange,
        )
        SegmentedRow(
            label = "Sound",
            options = listOf(
                SoundMode.OFF to "Off",
                SoundMode.SOFT to "Soft",
                SoundMode.ALARM to "Alarm",
            ),
            current = settings.soundMode,
            onSelect = onSoundModeChange,
        )
        ToggleRow(
            label = "Vibration",
            description = null,
            checked = settings.vibrationEnabled,
            onCheckedChange = onVibrationChange,
        )

        RedBand()

        Spacer(Modifier.height(24.dp))
        SectionHeading("OEM battery guidance")
        Spacer(Modifier.height(8.dp))
        OemGuidanceSection(ctx = ctx)

        RedBand()

        Spacer(Modifier.height(24.dp))
        SectionHeading("Privacy")
        Spacer(Modifier.height(8.dp))
        ActionRow(
            label = "Reset today's stats",
            description = "Delete completed/skipped/protected counters for today.",
            actionLabel = "Reset",
            onClick = onResetStats,
        )

        Spacer(Modifier.height(48.dp))
    }

    if (showAppPicker) {
        ExcludedAppPickerDialog(
            currentExcluded = settings.excludedPackages,
            onDismiss = { showAppPicker = false },
            onConfirm = { selected ->
                onExcludedPackagesChange(selected)
                showAppPicker = false
            },
        )
    }
}

@Composable
private fun SectionHeading(text: String) {
    Text(
        text,
        color = Charcoal,
        style = MaterialTheme.typography.headlineMedium,
        modifier = Modifier.padding(horizontal = 24.dp),
    )
}

@Composable
private fun PermissionList(permissions: PermissionsState, ctx: Context) {
    ChecklistRow(
        title = "Notifications",
        description = "Required to deliver break reminders.",
        granted = permissions.notifications,
        actionLabel = "Open",
        onAction = { PermissionLaunchers.openAppNotificationSettings(ctx) },
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
        title = "Do Not Disturb bypass",
        description = "Lets alarms break through DND.",
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
}

@Composable
private fun ExclusionListRow(
    excludedPackages: Set<String>,
    onManage: () -> Unit,
) {
    val ctx = LocalContext.current
    val pm = ctx.packageManager
    val count = excludedPackages.size
    val label = if (count == 0) "No excluded apps" else "$count excluded app${if (count > 1) "s" else ""}"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onManage)
            .padding(horizontal = 24.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text("Excluded apps", color = Charcoal, style = MaterialTheme.typography.titleMedium)
            Text(
                label,
                color = SecondaryGrey,
                style = MaterialTheme.typography.bodySmall,
            )
        }
        Text("Manage", color = VodafoneRed, style = MaterialTheme.typography.labelLarge)
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun ExcludedAppPickerDialog(
    currentExcluded: Set<String>,
    onDismiss: () -> Unit,
    onConfirm: (Set<String>) -> Unit,
) {
    val ctx = LocalContext.current
    var selected by remember { mutableStateOf(currentExcluded) }
    var apps by remember { mutableStateOf<List<Triple<String, String, android.graphics.drawable.Drawable>>>(emptyList()) }

    LaunchedEffect(Unit) {
        apps = loadInstalledApps(ctx)
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Exclude apps", color = Charcoal) },
        text = {
            if (apps.isEmpty()) {
                Text("Loading apps...", color = SecondaryGrey)
            } else {
                LazyColumn(modifier = Modifier.height(400.dp)) {
                    items(apps, key = { it.first }) { (pkg, label, icon) ->
                        val isSelected = pkg in selected
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    selected = if (isSelected) selected - pkg else selected + pkg
                                }
                                .padding(horizontal = 8.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Image(
                                bitmap = icon.toBitmap(48, 48).asImageBitmap(),
                                contentDescription = null,
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(RoundedCornerShape(6.dp)),
                            )
                            Spacer(Modifier.width(12.dp))
                            Column(Modifier.weight(1f)) {
                                Text(label, color = Charcoal, style = MaterialTheme.typography.bodyMedium)
                                Text(pkg, color = SecondaryGrey, style = MaterialTheme.typography.bodySmall)
                            }
                            if (isSelected) {
                                Icon(Icons.Filled.Check, contentDescription = null, tint = VodafoneRed)
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(selected) }) {
                Text("Done", color = VodafoneRed)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = SecondaryGrey)
            }
        },
    )
}

private fun loadInstalledApps(context: Context): List<Triple<String, String, android.graphics.drawable.Drawable>> {
    val pm = context.packageManager
    val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
    } else {
        @Suppress("DEPRECATION")
        pm.queryIntentActivities(intent, 0)
    }
    return resolveInfos
        .filter { it.activityInfo.packageName != context.packageName }
        .map { info ->
            val pkg = info.activityInfo.packageName
            val label = info.loadLabel(pm).toString()
            val icon = info.loadIcon(pm)
            Triple(pkg, label, icon)
        }
        .sortedBy { it.second.lowercase() }
}

@Composable
private fun SegmentedRow(
    label: String,
    options: List<Pair<ReminderStyle, String>>,
    current: ReminderStyle,
    onSelect: (ReminderStyle) -> Unit,
) {
    SegmentedRowGeneric(label = label, options = options, current = current, onSelect = onSelect)
}

@Composable
private fun SegmentedRow(
    label: String,
    options: List<Pair<SoundMode, String>>,
    current: SoundMode,
    onSelect: (SoundMode) -> Unit,
) {
    SegmentedRowGeneric(label = label, options = options, current = current, onSelect = onSelect)
}

@Composable
private fun <T> SegmentedRowGeneric(
    label: String,
    options: List<Pair<T, String>>,
    current: T,
    onSelect: (T) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 12.dp),
    ) {
        Text(label, color = Charcoal, style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(8.dp))
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            options.forEach { (value, name) ->
                val selected = value == current
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(40.dp)
                        .background(
                            if (selected) VodafoneRed else LightNeutral,
                            RoundedCornerShape(2.dp),
                        )
                        .clickable { onSelect(value) },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        name,
                        color = if (selected) CanvasWhite else Charcoal,
                        style = MaterialTheme.typography.labelLarge,
                    )
                }
            }
        }
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun ToggleRow(
    label: String,
    description: String?,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(label, color = Charcoal, style = MaterialTheme.typography.titleMedium)
            if (description != null) {
                Text(description, color = SecondaryGrey, style = MaterialTheme.typography.bodySmall)
            }
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = CanvasWhite,
                checkedTrackColor = VodafoneRed,
                checkedBorderColor = VodafoneRed,
            ),
        )
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun ActionRow(
    label: String,
    description: String,
    actionLabel: String,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(label, color = Charcoal, style = MaterialTheme.typography.titleMedium)
            Text(description, color = SecondaryGrey, style = MaterialTheme.typography.bodySmall)
        }
        Text(actionLabel, color = VodafoneRed, style = MaterialTheme.typography.labelLarge)
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun OemGuidanceSection(ctx: Context) {
    val manufacturer = Build.MANUFACTURER.lowercase()
    val guidance = detectOemGuidance(manufacturer)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 12.dp),
    ) {
        guidance.forEach { (title, body, action) ->
            OemGuidanceItem(title = title, body = body, actionLabel = action, ctx = ctx)
            Spacer(Modifier.height(12.dp))
        }
        if (guidance.isEmpty()) {
            Text(
                "Your device (${Build.MANUFACTURER}) should work without extra setup.",
                color = SecondaryGrey,
                style = MaterialTheme.typography.bodyMedium,
            )
        }
    }
    HorizontalDivider(color = LightNeutral)
}

@Composable
private fun OemGuidanceItem(title: String, body: String, actionLabel: String?, ctx: Context) {
    Column {
        Text(title, color = Charcoal, style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(4.dp))
        Text(body, color = SecondaryGrey, style = MaterialTheme.typography.bodySmall)
        if (actionLabel != null) {
            Spacer(Modifier.height(8.dp))
            Text(
                text = actionLabel,
                color = VodafoneRed,
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier.clickable { openOemSettings(ctx) },
            )
        }
    }
}

private fun detectOemGuidance(manufacturer: String): List<Triple<String, String, String?>> {
    val items = mutableListOf<Triple<String, String, String?>>()
    when {
        manufacturer.contains("xiaomi") || manufacturer.contains("redmi") || manufacturer.contains("poco") -> {
            items += Triple(
                "MIUI: AutoStart permission",
                "Go to Settings > Apps > Manage apps > Retina Guard > Autostart. Enable it so the service survives reboots.",
                "Open auto-start"
            )
            items += Triple(
                "MIUI: Battery saver",
                "Set battery saver to 'No restrictions' for Retina Guard in Settings > Apps > Retina Guard > Battery saver.",
                null
            )
            items += Triple(
                "MIUI: Background limits",
                "Disable 'Restrict background activity' and lock Retina Guard in the recent apps tray (drag down on the card).",
                null
            )
        }
        manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
            items += Triple(
                "Huawei: App launch management",
                "Go to Settings > Battery > App launch. Set Retina Guard to 'Manage manually' and enable all three toggles (Auto-launch, Secondary launch, Run in background).",
                "Open battery settings"
            )
            items += Triple(
                "Huawei: Ignore optimizations",
                "In Settings > Battery, ensure Retina Guard is not optimized. Also enable it in Protected apps if available.",
                null
            )
        }
        manufacturer.contains("samsung") -> {
            items += Triple(
                "Samsung: Battery optimization",
                "Go to Settings > Apps > Retina Guard > Battery > Optimize battery usage. Exclude Retina Guard from optimization.",
                "Open battery settings"
            )
            items += Triple(
                "Samsung: Sleeping/Deep sleeping apps",
                "Check Settings > Battery > Background usage limits. Make sure Retina Guard is NOT in the sleeping or deep sleeping apps list.",
                null
            )
            items += Triple(
                "Samsung: Device care",
                "In Settings > Device care > Battery, add Retina Guard to 'Never sleeping apps' for best reliability.",
                null
            )
        }
        manufacturer.contains("oneplus") || manufacturer.contains("oppo") || manufacturer.contains("realme") -> {
            items += Triple(
                "Oppo/OnePlus: Auto-start",
                "Go to Settings > Apps > Retina Guard > Auto-start. Enable it.",
                "Open app settings"
            )
            items += Triple(
                "Oppo/OnePlus: Battery optimization",
                "In Settings > Battery > More settings, disable optimization for Retina Guard. Also lock the app in the recent apps overview.",
                null
            )
        }
        manufacturer.contains("vivo") -> {
            items += Triple(
                "Vivo: Background allowlist",
                "Go to Settings > Battery > High background power consumption. Enable Retina Guard.",
                "Open battery settings"
            )
            items += Triple(
                "Vivo: Auto-start",
                "Enable auto-start for Retina Guard in Settings > Apps > Retina Guard > Auto-start.",
                null
            )
        }
    }
    return items
}

private fun openOemSettings(ctx: Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        .setData(android.net.Uri.fromParts("package", ctx.packageName, null))
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    runCatching { ctx.startActivity(intent) }
}
