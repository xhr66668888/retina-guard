import Foundation
import ActivityKit
import UserNotifications
import UIKit

/// Centralized permission checking — port of Android PermissionsState + PermissionLaunchers.
///
/// iOS permission model (per Apple docs):
/// - Notification:  UNUserNotificationCenter.requestAuthorization (required)
/// - Background:    Automatic if Background App Refresh enabled in Settings
/// - Critical alerts: requires special entitlement from Apple
/// - Screen Time:   Family Controls framework, requires entitlement
/// - No DND bypass, no overlay, no exact alarm equivalent
///
/// We map Android's 7 permissions to iOS equivalents where they exist.

struct PermissionState {
    var notifications: Bool     = false
    var backgroundRefresh: Bool = false
    var timeSensitive: Bool     = false
    var liveActivities: Bool    = false

    static func read() async -> PermissionState {
        // Notification authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let notifications = settings.authorizationStatus == .authorized
        let timeSensitive = settings.timeSensitiveSetting == .enabled

        // Background app refresh
        let (backgroundRefresh, liveActivities) = await MainActor.run {
            (
                UIApplication.shared.backgroundRefreshStatus == .available,
                LiveActivityManager.shared.isEnabled
            )
        }

        return PermissionState(
            notifications: notifications,
            backgroundRefresh: backgroundRefresh,
            timeSensitive: timeSensitive,
            liveActivities: liveActivities
        )
    }

    var readyForBasic: Bool { notifications }
    var ready: Bool { readyCount == totalCount }

    var readyCount: Int {
        (notifications ? 1 : 0) +
        (timeSensitive ? 1 : 0) +
        (liveActivities ? 1 : 0) +
        (backgroundRefresh ? 1 : 0)
    }

    var totalCount: Int { 4 }
}

/// Permission request helpers
@MainActor
final class PermissionManager {

    static let shared = PermissionManager()
    private init() {}

    // MARK: - Notification permission (iOS 10+)

    func requestNotifications() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
            return granted
        } catch {
            return false
        }
    }

    func checkNotifications() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Open Settings (for manual permission changes)

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openBackgroundRefreshSettings() {
        // iOS doesn't have a direct URL for this; open general settings
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
