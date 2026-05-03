import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: PreferencesStore
    @State private var notifGranted = false
    @State private var bgGranted = false
    @State private var timeSensitiveGranted = false
    @State private var liveActivityGranted = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RETINA GUARD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("Charcoal"))
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    Text("PROTECT\nYOUR EYES")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundColor(Color("Charcoal"))
                        .padding(.top, 48)
                        .padding(.horizontal, 24)

                    Text("Every 20 minutes, take 20 seconds to look into the distance.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                    RedBand()

                    Text("Reliability checklist")
                        .font(.title2.bold())
                        .foregroundColor(Color("Charcoal"))
                        .padding(.horizontal, 24)

                    Text("Notifications are required; background refresh improves reliability.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)

                    ChecklistRow(
                        title: "Notifications",
                        description: "Required to deliver break reminders.",
                        granted: notifGranted,
                        actionLabel: "Allow"
                    ) {
                        Task {
                            _ = await PermissionManager.shared.requestNotifications()
                            await refreshPermissions()
                        }
                    }

                    ChecklistRow(
                        title: "Time-sensitive alerts",
                        description: "Allows reminders to break through Focus and summaries.",
                        granted: perms.timeSensitive,
                        actionLabel: "Open Settings"
                    ) {
                        PermissionManager.shared.openNotificationSettings()
                    }

                    ChecklistRow(
                        title: "Live Activity",
                        description: "Shows a real-time countdown on the Lock Screen and Dynamic Island.",
                        granted: perms.liveActivities,
                        actionLabel: "Open Settings"
                    ) {
                        PermissionManager.shared.openAppSettings()
                    }

                    ChecklistRow(
                        title: "Background refresh",
                        description: "Keeps the countdown running when app is backgrounded.",
                        granted: bgGranted,
                        actionLabel: "Open Settings"
                    ) {
                        PermissionManager.shared.openBackgroundRefreshSettings()
                    }
                }
            }

            // Bottom buttons
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    GhostRectangleButton(text: "Skip for now") {
                        store.setOnboardingDone(true)
                    }
                    RedPillButton(
                        text: ready ? "Continue" : "\(perms.readyCount)/\(perms.totalCount) ready",
                        enabled: ready
                    ) {
                        store.setOnboardingDone(true)
                    }
                }

                if !ready {
                    Text("Notifications are required to start.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .task {
            await refreshPermissions()
        }
    }

    private var perms: PermissionState {
        var p = PermissionState()
        p.notifications = notifGranted
        p.backgroundRefresh = bgGranted
        p.timeSensitive = timeSensitiveGranted
        p.liveActivities = liveActivityGranted
        return p
    }

    private var ready: Bool { notifGranted }

    private func refreshPermissions() async {
        let perms = await PermissionState.read()
        notifGranted = perms.notifications
        bgGranted = perms.backgroundRefresh
        timeSensitiveGranted = perms.timeSensitive
        liveActivityGranted = perms.liveActivities
    }
}
