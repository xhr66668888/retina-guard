# Retina Guard

Cross-platform eye protection app based on the **20-20-20 rule**: every 20 minutes, look at something 20 feet away for 20 seconds.

Available on **Android**, **iOS**, **macOS**, **Windows**, and **HarmonyOS**.

---

## Project Structure

```
retina-guard/
├── android/        Android app (Kotlin, Jetpack Compose)
├── ios/            iOS app (Swift, SwiftUI)
├── mac/            macOS desktop app (Go)
├── windows/        Windows desktop app (Go, Win32 API)
└── harmonyos/      HarmonyOS app (ArkTS, ArkUI)
```

---

## Android

**Language:** Kotlin 2.0 · **UI:** Jetpack Compose (Material 3) · **Min SDK:** 26 · **Target SDK:** 35

### Features

- Foreground service with live countdown notification
- Full-screen alarm / heads-up / overlay reminder styles
- Sound modes (off, soft, alarm) and vibration
- Usage-aware mode: counts actual screen-on time via `UsageStatsManager`
- Excluded apps list (skip certain apps from usage accumulation)
- Quiet hours (22:00–08:00) and daily schedule (configurable days/hours)
- OEM battery optimization guidance (Xiaomi, Huawei, Samsung, OnePlus, Vivo)
- 7-point reliability checklist with permission management
- Onboarding flow, today stats, break screen with snooze/skip

### Prerequisites

- [Android Studio](https://developer.android.com/studio) Ladybug or later
- JDK 17+
- Android SDK 35

### Build

```bash
cd android/
./gradlew assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

### Permissions

| Permission | Purpose |
|---|---|
| `POST_NOTIFICATIONS` | Deliver break reminders |
| `SCHEDULE_EXACT_ALARM` | Fire alarms on time in standby |
| `USE_FULL_SCREEN_INTENT` | Show alarm over lock screen |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent OS from killing service |
| `ACCESS_NOTIFICATION_POLICY` | Bypass DND for alarms |
| `SYSTEM_ALERT_WINDOW` | Overlay nudge on other apps |
| `PACKAGE_USAGE_STATS` | Usage-aware screen time tracking |
| `RECEIVE_BOOT_COMPLETED` | Re-arm alarms after reboot |
| `FOREGROUND_SERVICE` | Keep countdown alive |

---

## iOS

**Language:** Swift 5.9 · **UI:** SwiftUI · **Min iOS:** 16.0

### Features

- `UNUserNotificationCenter` with time-sensitive break reminders
- `BGAppRefreshTaskRequest` for background countdown (best-effort)
- Foreground usage-aware tracking via `scenePhase`
- Quiet hours and daily schedule
- Notification action buttons (Done, Snooze, Skip)
- Full-screen dark break screen
- iOS-specific battery/background tips in settings

### Prerequisites

- macOS with **Xcode 15+**
- Apple Developer account (for device testing)

### Build

```bash
cd ios/
chmod +x setup.sh
./setup.sh              # Requires: brew install xcodegen
open RetinaGuard.xcodeproj
# Or: open Xcode, create new SwiftUI project, drag in RetinaGuard/ files
```

### Permission Model (iOS vs Android)

| Android | iOS Equivalent | Notes |
|---|---|---|
| `POST_NOTIFICATIONS` | `requestAuthorization(.alert, .sound, .badge)` | User prompt, no plist key needed |
| `SCHEDULE_EXACT_ALARM` | `UNTimeIntervalNotificationTrigger` | OS-managed, no special permission |
| `FOREGROUND_SERVICE` | `Timer.publish` + `scenePhase` | Timer pauses on background |
| `RUNNING_BACKGROUND` | `BGAppRefreshTask` + UIBackgroundModes | Best-effort, OS may skip |
| `PACKAGE_USAGE_STATS` | `DeviceActivityMonitor` (needs entitlement) | Requires Apple approval; fallback to foreground tracking |
| `SYSTEM_ALERT_WINDOW` | Not available | iOS does not support overlays |
| `USE_FULL_SCREEN_INTENT` | `UNNotificationInterruptionLevel.timeSensitive` | No full-screen alarm on iOS |
| `ACCESS_NOTIFICATION_POLICY` | Focus / DND whitelist | Guide user to add app to allowed list |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Not available | Guide user to disable Low Power Mode |

---

## macOS

**Language:** Go 1.22+ · **UI:** Terminal · **Deps:** None

### Features

- Terminal UI with colored output
- Configurable interval (1–60 min)
- Native macOS notifications via `osascript`
- Glass sound effect via `afplay`
- Start/stop/interval commands

### Build

```bash
cd mac/
# On Mac:
go build -o retina-guard .

# Cross-compile from Linux:
GOOS=darwin GOARCH=amd64 go build -o retina-guard-mac .
GOOS=darwin GOARCH=arm64 go build -o retina-guard-mac-arm64 .
```

### Run

```bash
chmod +x retina-guard-mac
./retina-guard
```

Commands: `s`/start, `x`/stop, `1-60` set interval, `q`/quit, `h`/help

### Build .app bundle and DMG

The `mac/` folder includes a pre-built `RetinaGuard.app` and `build-dmg.sh`:

```bash
cd mac/
./build-dmg.sh          # Creates RetinaGuard.dmg (requires macOS)
```

---

## Windows

**Language:** Go 1.22+ · **UI:** Win32 API · **Deps:** None

### Features

- Native Win32 window with message loop
- Interval selector dropdown (1–60 min)
- Start/stop button
- `MessageBoxW` reminders (topmost, always visible)
- ~1.3 MB binary, zero dependencies

### Build

```bash
cd windows/

# On Windows:
go build -o retina-guard.exe .

# Cross-compile from Linux/Mac:
GOOS=windows GOARCH=amd64 go build -o retina-guard.exe .
```

### Run

Double-click `retina-guard.exe` or run from terminal:

```
retina-guard.exe
```

---

## HarmonyOS

**Language:** ArkTS · **UI:** ArkUI (declarative) · **API:** 12+ · **IDE:** DevEco Studio

### Features

- 3-tab navigation (Today / Schedule / Settings)
- `reminderAgentManager` for scheduled break alarms
- Notification channels for ongoing and break reminders
- Quiet hours and daily schedule with day-of-week picker
- Usage-aware screen time tracking
- Permission management (notifications + reminder agent)
- Full-screen break page with dark theme
- OEM battery guidance for Huawei, Xiaomi, Samsung, Oppo, Vivo

### Prerequisites

- [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) 5.0+
- HarmonyOS SDK (API 12+)
- Huawei Developer account

### Build

1. Open DevEco Studio
2. **File > Open** → select the `harmonyos/` folder
3. Wait for Gradle sync to complete
4. **Build > Build Hap(s)/APP(s) > Build Hap(s)**

### Run

- **Emulator:** Tools > Device Manager → create a phone emulator → Run
- **Device:** Connect a HarmonyOS device → Run (requires developer mode)

### Permissions

| Permission | Purpose |
|---|---|
| `ohos.permission.PUBLISH_AGENT_REMINDER` | Schedule break reminder alarms |
| `ohos.permission.RUNNING_BACKGROUND` | Keep countdown service running |

---

## License

MIT
