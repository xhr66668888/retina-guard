import UserNotifications
import UIKit
import AudioToolbox

/// Wraps UNUserNotificationCenter — port of Android NotificationHelper.
@MainActor
final class NotificationManager: NSObject, @preconcurrency UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    // Channel IDs (iOS uses categories instead)
    static let catBreak    = "EYE_BREAK_REMINDER"
    static let catOngoing  = "PROTECTION_ONGOING"

    // Notification IDs
    static let notifOngoing = "protection_ongoing"
    static let notifBreak   = "eye_break"

    private override init() { super.init() }

    // MARK: - Setup

    func configure() {
        center.delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 5m", options: [])
        let skip   = UNNotificationAction(identifier: "SKIP", title: "Skip", options: [])
        let done   = UNNotificationAction(identifier: "DONE", title: "Done", options: [.foreground])
        let start  = UNNotificationAction(identifier: "START_BREAK", title: "Start break", options: [.foreground])

        let breakCat = UNNotificationCategory(
            identifier: Self.catBreak,
            actions: [done, start, snooze, skip],
            intentIdentifiers: [],
            options: [.allowInCarPlay]
        )
        let ongoingCat = UNNotificationCategory(
            identifier: Self.catOngoing,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([breakCat, ongoingCat])
    }

    // MARK: - Permission (iOS 10+ requires explicit authorization)

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Post ongoing notification

    func postOngoing(remainingSeconds: Int) {
        let mins = max(0, remainingSeconds) / 60
        let secs = max(0, remainingSeconds) % 60
        let title = String(format: "Next break in %02d:%02d", mins, secs)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = "Retina Guard is running"
        content.categoryIdentifier = Self.catOngoing
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.notifOngoing, content: content, trigger: trigger)
        center.add(req, withCompletionHandler: nil)
    }

    // MARK: - Post break reminder

    func postBreakReminder(settings: AppSettings) {
        let content = breakReminderContent(settings: settings)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.notifBreak, content: content, trigger: trigger)
        center.add(req, withCompletionHandler: nil)
    }

    // MARK: - Schedule future break (for background)

    func scheduleBreakReminder(at date: Date, settings: AppSettings, repeats: Bool = false) {
        let content = breakReminderContent(settings: settings)
        let interval = max(60, date.timeIntervalSinceNow)
        let triggerInterval = repeats ? max(60, Double(settings.intervalMinutes) * 60) : max(1, interval)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: repeats)
        let req = UNNotificationRequest(identifier: Self.notifBreak, content: content, trigger: trigger)
        center.add(req, withCompletionHandler: nil)
    }

    private func breakReminderContent(settings: AppSettings) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Time to look away"
        content.body  = "Focus on something far away for 20 seconds."
        content.categoryIdentifier = Self.catBreak
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0

        switch settings.soundMode {
        case .off:   content.sound = nil
        case .soft:  content.sound = .default
        case .alarm:
            content.sound = UNNotificationSound(
                named: UNNotificationSoundName(rawValue: "retina_alarm.caf")
            )
        }

        return content
    }

    // MARK: - Cancel

    func cancelBreak() {
        center.removeDeliveredNotifications(withIdentifiers: [Self.notifBreak])
        center.removePendingNotificationRequests(withIdentifiers: [Self.notifBreak])
    }

    func cancelOngoing() {
        center.removeDeliveredNotifications(withIdentifiers: [Self.notifOngoing])
        center.removePendingNotificationRequests(withIdentifiers: [Self.notifOngoing])
    }

    func cancelAll() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate (foreground presentation)

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == Self.notifOngoing {
            completionHandler([])
        } else {
            if PreferencesStore.shared.settings.vibrationEnabled {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            completionHandler([.banner, .sound, .badge])
        }
    }

    // MARK: - Handle notification actions

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let store = PreferencesStore.shared
        let id = response.notification.request.identifier
        let action = response.actionIdentifier

        if id == Self.notifBreak {
            switch action {
            case "DONE", "START_BREAK":
                store.recordCompleted()
                store.resetAccumulatedMs()
                let due = Date().addingTimeInterval(Double(store.settings.intervalMinutes) * 60)
                store.setNextDueAt(due)
                AlarmScheduler.shared.scheduleNextBreak()
            case "SNOOZE":
                store.clearReminderOutstanding()
                store.resetAccumulatedMs()
                let due = Date().addingTimeInterval(Double(store.settings.snoozeMinutes) * 60)
                store.setNextDueAt(due)
                NotificationManager.shared.cancelBreak()
                NotificationManager.shared.scheduleBreakReminder(at: due, settings: store.settings)
                LiveActivityManager.shared.updateCountdown(nextDueAt: due, settings: store.settings)
            case "SKIP":
                store.recordSkipped()
                store.resetAccumulatedMs()
                let due = Date().addingTimeInterval(Double(store.settings.intervalMinutes) * 60)
                store.setNextDueAt(due)
                AlarmScheduler.shared.scheduleNextBreak()
            default:
                break
            }
        }
        completionHandler()
    }
}
