# Retina Guard

Cross-platform eye protection app based on the **20-20-20 rule**: every 20 minutes, look at something 20 feet away for 20 seconds.

Available on **Android**, **iOS**, **macOS**, **Windows**, and **HarmonyOS**.

---

## Project Structure

```
retina-guard/
├── android/        Android app (Kotlin, Jetpack Compose)
├── ios/            iOS app (Swift, SwiftUI)
├── mac/            macOS desktop app (Objective-C, AppKit; arm64 + x64 packages)
├── windows/        Windows desktop app (Go, Win32 API; x64 + arm64 packages)
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

**Language:** Swift 6 · **UI:** SwiftUI + ActivityKit · **Min iOS:** 16.2

### Features

- `UNUserNotificationCenter` with time-sensitive break reminders
- Live Activity countdown on the Lock Screen and Dynamic Island
- Prominent break alerts with bundled alarm sound, vibration path, and Done/Snooze/Skip actions
- `BGAppRefreshTaskRequest` for background countdown (best-effort)
- Foreground usage-aware tracking via `scenePhase`
- Quiet hours and daily schedule
- Notification action buttons (Done, Snooze, Skip)
- Full-screen dark break screen
- iOS-specific battery/background tips in settings
- Android/iOS acceptance notes: [`ios/PARITY.md`](ios/PARITY.md)

### Prerequisites

- macOS with **Xcode 16+**
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
| `RUNNING_BACKGROUND` | Live Activity + `BGAppRefreshTask` + UIBackgroundModes | Live Activity keeps visible countdown; BG refresh is best-effort |
| `PACKAGE_USAGE_STATS` | `DeviceActivityMonitor` (needs entitlement) | Requires Apple approval; fallback to foreground tracking |
| `SYSTEM_ALERT_WINDOW` | Not available | iOS does not support overlays |
| `USE_FULL_SCREEN_INTENT` | `UNNotificationInterruptionLevel.timeSensitive` + Live Activity alert update | No Android-style full-screen alarm on iOS |
| `ACCESS_NOTIFICATION_POLICY` | Focus / DND whitelist | Guide user to add app to allowed list |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Not available | Guide user to disable Low Power Mode |

---

## macOS

**Language:** Objective-C · **UI:** Native Cocoa/AppKit · **Deps:** None · **CPU:** Apple Silicon arm64 + Intel x64

### Features

- Native macOS window with interval selector and start/stop button
- Configurable interval (1–60 min) via dropdown
- Blocking `NSAlert` reminder (topmost, like Windows `MessageBox`)
- Glass sound effect via `NSSound`
- Quit via ⌘Q or close window

### Build

```bash
cd mac/
# On Apple Silicon Mac (requires Xcode Command Line Tools):
./build-all.sh
```

Outputs:

| Target | Folder | Artifact |
|---|---|---|
| Apple Silicon Mac | `mac/arm64/` | `RetinaGuard-mac-arm64.dmg` |
| Intel Mac | `mac/x64/` | `RetinaGuard-mac-x64.dmg` |

`mac/build-dmg.sh` is kept as a compatibility wrapper and also builds both packages.
The legacy root artifact `mac/RetinaGuard.dmg` is kept as the Apple Silicon build.
This version builds with Apple clang and AppKit, so it must be built on macOS.

### Run

```bash
open RetinaGuard.app
```

### Build .app bundle and DMG

The `mac/` folder includes pre-built architecture-specific app bundles and build scripts:

```bash
cd mac/
./build-all.sh
```

The DMG build scripts verify the requested architecture and apply a local ad-hoc signature. For public distribution, build with `SIGN_IDENTITY="Developer ID Application: ..."` and notarize the DMG with Apple.

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

# Cross-compile both 64-bit packages from Linux/Mac:
./build-all.sh
```

Outputs:

| Target | Folder | Artifact |
|---|---|---|
| x86 PC | `windows/x64/` | `retina-guard-windows-x64.exe` |
| Windows on ARM | `windows/arm64/` | `retina-guard-windows-arm64.exe` |

The legacy root artifact `windows/retina-guard.exe` is kept as the x64 Windows build.

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
