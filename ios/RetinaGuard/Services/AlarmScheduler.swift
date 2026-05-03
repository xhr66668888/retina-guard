import Foundation
import UIKit
import BackgroundTasks

/// Schedules notifications that fire when break is due —
/// port of Android AlarmScheduler + AlarmReceiver.
@MainActor
final class AlarmScheduler {

    static let shared = AlarmScheduler()
    private init() {}

    private let notifMgr = NotificationManager.shared
    private let store    = PreferencesStore.shared

    // MARK: - Schedule next break

    func scheduleNextBreak() {
        guard store.session.protectionRunning else { return }
        let due = store.session.nextDueAt
        guard due > Date() else { return }

        // Cancel existing pending break and reschedule
        notifMgr.cancelBreak()
        notifMgr.scheduleBreakReminder(
            at: due,
            settings: store.settings,
            repeats: shouldUseRepeatingReminder(for: due)
        )

        if store.session.reminderOutstanding {
            LiveActivityManager.shared.showBreakDue(settings: store.settings)
        } else {
            LiveActivityManager.shared.updateCountdown(nextDueAt: due, settings: store.settings)
        }

        // Also register a BGAppRefreshTask as a fallback
        scheduleBackgroundRefresh(at: due)
    }

    // MARK: - Reschedule after app foreground

    func rescheduleOnForeground() {
        guard store.session.protectionRunning else { return }
        let now = Date()
        let due = store.session.nextDueAt

        if now >= due && due != .distantPast {
            // Break is overdue — fire it now
            onBreakDue()
        } else {
            // Re-schedule the pending notification
            scheduleNextBreak()
        }
    }

    // MARK: - Break due handler (port of Android AlarmReceiver)

    func onBreakDue() {
        guard store.session.protectionRunning else { return }

        // Missed tracking
        if store.session.reminderOutstanding {
            store.recordMissed()
        }

        // Quiet hours check
        if store.settings.quietHoursEnabled, isQuietHour() {
            deferToNextAllowed()
            return
        }

        // Daily schedule check
        if store.settings.dailyScheduleEnabled, !isInDailyWindow() {
            deferToNextAllowed()
            return
        }

        store.markReminderShown()
        LiveActivityManager.shared.showBreakDue(settings: store.settings)
        notifMgr.postBreakReminder(settings: store.settings)

        // Schedule next cycle
        let nextDue = Date().addingTimeInterval(Double(store.settings.intervalMinutes) * 60)
        store.setNextDueAt(nextDue)
        store.resetAccumulatedMs()
        scheduleNextBreak()
    }

    // MARK: - Cancel everything

    func cancelAll() {
        notifMgr.cancelAll()
        LiveActivityManager.shared.end()
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.retinaguard.refresh")
    }

    private func shouldUseRepeatingReminder(for due: Date) -> Bool {
        guard !store.settings.quietHoursEnabled, !store.settings.dailyScheduleEnabled else {
            return false
        }

        let expectedInterval = Double(store.settings.intervalMinutes) * 60
        let actualInterval = due.timeIntervalSinceNow
        return abs(actualInterval - expectedInterval) < 10
    }

    // MARK: - Background refresh (best-effort on iOS)

    private func scheduleBackgroundRefresh(at date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: "com.retinaguard.refresh")
        request.earliestBeginDate = date
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Background scheduling is best-effort on iOS
        }
    }

    // MARK: - Quiet hours (22:00 – 08:00)

    private func isQuietHour() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 22 || hour < 8
    }

    // MARK: - Daily window (09:00 – 18:00 on active days)

    private func isInDailyWindow() -> Bool {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun
        let hour = cal.component(.hour, from: now)
        let active = store.settings.activeDaysMask & (1 << (weekday - 1)) != 0
        return active && hour >= 9 && hour < 18
    }

    private func deferToNextAllowed() {
        // Simple: schedule for next 09:00
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9; comps.minute = 0; comps.second = 0
        var next = cal.date(from: comps)!
        if next <= Date() { next = cal.date(byAdding: .day, value: 1, to: next)! }
        store.setNextDueAt(next)
        scheduleNextBreak()
    }
}
