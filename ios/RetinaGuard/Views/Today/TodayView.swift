import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: PreferencesStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var tracker = ScreenUsageTracker()
    @State private var now = Date()
    @State private var timerRunning = false
    @State private var tickTimer: Timer?

    private var remainingSec: Int {
        if store.session.protectionRunning {
            return max(0, Int(store.session.nextDueAt.timeIntervalSince(now)))
        }
        return store.settings.intervalMinutes * 60
    }

    private var timerText: String {
        let m = remainingSec / 60
        let s = remainingSec % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var subText: String {
        if store.session.protectionRunning {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return "next break at \(f.string(from: store.session.nextDueAt))"
        }
        return "until your next eye break"
    }

    private var protectedLabel: String {
        let h = store.stats.protectedSeconds / 3600
        let m = (store.stats.protectedSeconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("RETINA GUARD")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("Charcoal"))
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                // Timer hero
                VStack(alignment: .leading, spacing: 8) {
                    Text(timerText)
                        .font(.system(size: 80, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color("Charcoal"))

                    Text(subText)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                // Buttons
                if store.session.protectionRunning {
                    HStack(spacing: 12) {
                        GhostRectangleButton(text: "Stop") { stopProtection() }
                        RedPillButton(text: "Take break now", enabled: true) { takeBreakNow() }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                } else {
                    RedPillButton(
                        text: "Start protection",
                        enabled: store.settings.onboardingDone
                    ) { startProtection() }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                }

                // Interval picker
                if !store.session.protectionRunning {
                    Text("INTERVAL")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        ForEach(intervalChoices, id: \.self) { value in
                            Button("\(value)") {
                                store.setInterval(value)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(value == store.settings.intervalMinutes ? Color.red : Color(.systemGray6))
                            .foregroundColor(value == store.settings.intervalMinutes ? .white : Color("Charcoal"))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    Text("minutes between breaks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.horizontal, 24)
                }

                RedBand()

                // Stats
                Text("Today")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.horizontal, 24)

                HStack {
                    StatTile(label: "COMPLETED", value: "\(store.stats.completed)")
                    StatTile(label: "SKIPPED", value: "\(store.stats.skipped)")
                    StatTile(label: "PROTECTED", value: protectedLabel)
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)

                // Reliability
                Text("Reliability")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                ReliabilityCard()
                    .padding(.top, 8)
                    .padding(.horizontal, 24)

                if store.session.protectionRunning {
                    Text("Background")
                        .font(.title2.bold())
                        .foregroundColor(Color("Charcoal"))
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    HStack {
                        Text("Next break")
                            .font(.subheadline)
                        Spacer()
                        Text(store.session.nextDueAt > Date() ? "scheduled" : "overdue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .onAppear {
            now = Date()
            LiveActivityManager.shared.syncFromStore(store)
            startTicking()
        }
        .onDisappear { stopTicking() }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                now = Date()
                AlarmScheduler.shared.rescheduleOnForeground()
                LiveActivityManager.shared.syncFromStore(store)
            }
        }
    }

    // MARK: - Actions

    private func startProtection() {
        let now = Date()
        let due = now.addingTimeInterval(Double(store.settings.intervalMinutes) * 60)
        store.startProtection(nextDueAt: due, now: now)
        if store.settings.usageAwareEnabled {
            tracker.start(initialMs: 0)
        }
        LiveActivityManager.shared.start(nextDueAt: due, settings: store.settings)
        AlarmScheduler.shared.scheduleNextBreak()
        startTicking()
    }

    private func stopProtection() {
        stopTicking()
        _ = tracker.stop()
        store.stopProtection(now: Date())
        NotificationManager.shared.cancelOngoing()
        AlarmScheduler.shared.cancelAll()
    }

    private func takeBreakNow() {
        // Post break notification immediately
        LiveActivityManager.shared.showBreakDue(settings: store.settings)
        NotificationManager.shared.postBreakReminder(settings: store.settings)
    }

    private func startTicking() {
        timerRunning = store.session.protectionRunning
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                now = Date()

                guard store.session.protectionRunning else {
                    stopTicking()
                    return
                }

                if store.settings.usageAwareEnabled {
                    tracker.tick()
                    let accum = tracker.getAccumulatedMs()
                    let intervalMs = store.settings.intervalMinutes * 60_000
                    if accum >= intervalMs {
                        onBreakDue()
                        tracker.reset()
                    }
                } else {
                    if now >= store.session.nextDueAt && store.session.nextDueAt != .distantPast {
                        onBreakDue()
                    }
                }

                if remainingSec <= 0 {
                    LiveActivityManager.shared.showBreakDue(settings: store.settings)
                }
            }
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
        timerRunning = false
    }

    private func onBreakDue() {
        AlarmScheduler.shared.onBreakDue()
    }
}

// MARK: - Sub-views

struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(Color("Charcoal"))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReliabilityCard: View {
    @EnvironmentObject var store: PreferencesStore
    @State private var perms = PermissionState()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(perms.ready ? "All permissions ready" : "\(perms.readyCount)/\(perms.totalCount) permissions ready")
                    .font(.headline)
                Spacer()
                Text("Review")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            Text(perms.ready ? "Retina Guard can deliver reminders reliably." : "Finish setup to make reminders more reliable.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray5), lineWidth: 1))
        .task { perms = await PermissionState.read() }
    }
}
