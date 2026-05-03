# iOS Parity Notes

This document is the acceptance checklist for comparing the iOS app with the
Android implementation.

## Summary

iOS now covers the same product goal as Android: a reliable eye-rest reminder
with countdown visibility, prominent alerts, scheduling rules, snooze/skip
actions, app icon packaging, and permission status checks.

It is not a literal one-to-one Android clone, because iOS does not expose public
equivalents for several Android system capabilities such as foreground services,
system overlays, exact alarm permissions, or unrestricted app usage stats. The
iOS implementation therefore uses the strongest Apple-approved equivalents:
ActivityKit Live Activities, Dynamic Island, Lock Screen presentation, local
notifications, Time Sensitive interruption level, a bundled alarm sound, and
foreground scene synchronization.

## Implemented In This Build

| Area | Android behavior | iOS behavior now |
|---|---|---|
| Countdown while app is visible | Foreground service notification and in-app timer | In-app SwiftUI timer with immediate scene refresh |
| Countdown while app is backgrounded | Foreground service keeps live notification current | Live Activity shows the countdown on Lock Screen and Dynamic Island |
| Dynamic Island | N/A | Widget extension with compact, expanded, and minimal Live Activity layouts |
| Break due alert | Heads-up/full-screen/overlay modes | Time Sensitive local notification plus Live Activity alert update |
| Sound | Off/soft/alarm | Off/soft/default/alarm using bundled `retina_alarm.caf` |
| Vibration | Configurable vibration | Foreground vibration trigger and notification sound/haptic path |
| Notification actions | Done/snooze/skip | Done/snooze/skip actions in local notifications |
| Quiet hours/schedule | Configurable | Configurable |
| App icon | Packaged launcher icon | Full iOS AppIcon asset catalog generated and packaged |
| Swift 6 build | N/A | Swift 6 build passes for simulator and unsigned iphoneos Release |

## Platform Limits

| Android capability | iOS status | Product decision |
|---|---|---|
| `FOREGROUND_SERVICE` | No general public equivalent for keeping arbitrary app code alive | Use Live Activity for visible countdown and notifications for delivery |
| `SYSTEM_ALERT_WINDOW` | No public overlay API | Use Lock Screen/Dynamic Island/banner notification |
| `USE_FULL_SCREEN_INTENT` | No Android-style full-screen alarm for normal apps | Use Time Sensitive alerts; critical alerts require Apple approval |
| `SCHEDULE_EXACT_ALARM` | No user-granted exact alarm permission | Use local notification scheduling and a repeating fallback when schedule rules allow |
| `ACCESS_NOTIFICATION_POLICY` | Apps cannot bypass Focus/DND without specific user settings or critical-alert entitlement | Surface permission status and guide users to allow alerts |
| `PACKAGE_USAGE_STATS` | Screen Time data requires FamilyControls/DeviceActivity entitlement | Current app uses foreground tracking; full cross-app monitoring needs Apple entitlement approval |

## Apple References

- ActivityKit and Live Activities: https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- Dynamic Island Live Activity layouts: https://developer.apple.com/documentation/widgetkit/dynamicisland
- Time Sensitive notifications: https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
- Custom notification sounds: https://developer.apple.com/documentation/usernotifications/unnotificationsound
- Critical Alerts entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts
- Device Activity framework: https://developer.apple.com/documentation/deviceactivity
- Family Controls entitlement: https://developer.apple.com/documentation/familycontrols

## Real-device Acceptance Checklist

1. Install on an iPhone with Dynamic Island and grant notifications.
2. Start protection, lock the phone, and confirm the countdown appears as a Live Activity.
3. Background the app and wait for the reminder interval; the Dynamic Island/Lock Screen countdown should continue visually.
4. Confirm the break alert uses sound and Time Sensitive delivery when allowed by Settings.
5. Test Done, Snooze, and Skip from the notification actions.
6. Confirm the app icon appears on the Home Screen after install.

