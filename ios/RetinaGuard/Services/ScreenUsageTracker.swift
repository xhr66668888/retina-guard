import Foundation
import UIKit
import Combine

/// Tracks foreground screen-on time — port of Android ScreenUsageTracker.
/// iOS cannot track other apps' usage without Family Controls entitlement,
/// so this tracks foreground time of *this* app only.
/// When usage-aware is on, the timer only counts while the app is active.
final class ScreenUsageTracker: ObservableObject {

    private var accumulatedMs: Int = 0
    private var lastResumeTime: Date?
    private var cancellables = Set<AnyCancellable>()

    @Published var isPaused: Bool = false

    init() {
        // Observe app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.onForeground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.onBackground() }
            .store(in: &cancellables)
    }

    // MARK: - Control

    func start(initialMs: Int = 0) {
        accumulatedMs = initialMs
        lastResumeTime = Date()
        isPaused = false
    }

    func stop() -> Int {
        flush()
        let result = accumulatedMs
        lastResumeTime = nil
        return result
    }

    func getAccumulatedMs() -> Int {
        flush()
        return accumulatedMs
    }

    func reset() {
        accumulatedMs = 0
        lastResumeTime = Date()
    }

    // MARK: - Tick (call from a 1-second Timer in the view)

    func tick() {
        guard lastResumeTime != nil, !isPaused else { return }
        let now = Date()
        let delta = Int(now.timeIntervalSince(lastResumeTime!) * 1000)
        accumulatedMs += delta
        lastResumeTime = now
    }

    // MARK: - Lifecycle

    private func onForeground() {
        if lastResumeTime != nil {
            lastResumeTime = Date()
        }
        isPaused = false
    }

    private func onBackground() {
        flush()
        isPaused = true
    }

    private func flush() {
        guard let last = lastResumeTime else { return }
        let delta = Int(Date().timeIntervalSince(last) * 1000)
        accumulatedMs += max(0, delta)
        lastResumeTime = Date()
    }
}
