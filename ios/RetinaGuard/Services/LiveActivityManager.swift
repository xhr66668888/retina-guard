@preconcurrency import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RetinaGuardActivityAttributes>? {
        Activity<RetinaGuardActivityAttributes>.activities.first
    }

    var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(nextDueAt: Date, settings: AppSettings) {
        guard isEnabled else { return }

        if activity != nil {
            updateCountdown(nextDueAt: nextDueAt, settings: settings)
            return
        }

        let attributes = RetinaGuardActivityAttributes(title: "Retina Guard")
        let state = contentState(nextDueAt: nextDueAt, settings: settings, phase: .countdown)
        let content = ActivityContent(state: state, staleDate: nextDueAt)

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activities can be disabled by the user or unavailable on the device.
        }
    }

    func syncFromStore(_ store: PreferencesStore) {
        guard store.session.protectionRunning else {
            end()
            return
        }

        if store.session.reminderOutstanding || store.session.nextDueAt <= Date() {
            showBreakDue(settings: store.settings)
        } else if activity == nil {
            start(nextDueAt: store.session.nextDueAt, settings: store.settings)
        } else {
            updateCountdown(nextDueAt: store.session.nextDueAt, settings: store.settings)
        }
    }

    func updateCountdown(nextDueAt: Date, settings: AppSettings) {
        guard let activity else {
            start(nextDueAt: nextDueAt, settings: settings)
            return
        }

        let state = contentState(nextDueAt: nextDueAt, settings: settings, phase: .countdown)
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nextDueAt))
        }
    }

    func showBreakDue(settings: AppSettings) {
        guard let activity else { return }

        let state = contentState(nextDueAt: Date(), settings: settings, phase: .breakDue)
        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: Date()),
                alertConfiguration: AlertConfiguration(
                    title: "Time to look away",
                    body: "Focus on something far away for 20 seconds.",
                    sound: .default
                )
            )
        }
    }

    func end() {
        guard let activity else { return }
        let state = RetinaGuardActivityAttributes.ContentState(
            nextDueAt: Date(),
            intervalMinutes: 0,
            breakSeconds: 0,
            phase: .paused
        )

        Task {
            await activity.end(
                ActivityContent(state: state, staleDate: Date()),
                dismissalPolicy: .immediate
            )
        }
    }

    private func contentState(
        nextDueAt: Date,
        settings: AppSettings,
        phase: RetinaGuardActivityAttributes.Phase
    ) -> RetinaGuardActivityAttributes.ContentState {
        RetinaGuardActivityAttributes.ContentState(
            nextDueAt: nextDueAt,
            intervalMinutes: settings.intervalMinutes,
            breakSeconds: settings.breakSeconds,
            phase: phase
        )
    }
}
