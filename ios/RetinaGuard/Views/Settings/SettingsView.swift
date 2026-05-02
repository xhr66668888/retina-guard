import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PreferencesStore
    @State private var perms = PermissionState()
    @State private var showExclusionPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SETTINGS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("Charcoal"))
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                // MARK: - Reliability
                Text("Reliability")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                ChecklistRow(
                    title: "Notifications",
                    description: "Required to deliver break reminders.",
                    granted: perms.notifications,
                    actionLabel: "Open"
                ) {
                    PermissionManager.shared.openNotificationSettings()
                }

                ChecklistRow(
                    title: "Background refresh",
                    description: "Keeps countdown running when app is backgrounded.",
                    granted: perms.backgroundRefresh,
                    actionLabel: "Open"
                ) {
                    PermissionManager.shared.openBackgroundRefreshSettings()
                }

                RedBand()

                // MARK: - Usage-aware mode
                Text("Usage-aware mode")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.horizontal, 24)

                Toggle(isOn: Binding(
                    get: { store.settings.usageAwareEnabled },
                    set: { store.setUsageAware($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen-time tracking")
                            .font(.body.weight(.medium))
                        Text("Count only foreground time toward breaks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.red)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                if store.settings.usageAwareEnabled {
                    Divider()

                    Button { showExclusionPicker = true } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Excluded apps")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(Color("Charcoal"))
                                Text(exclusionLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Manage")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }

                RedBand()

                // MARK: - Reminder
                Text("Reminder")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.horizontal, 24)

                // Style segmented
                VStack(alignment: .leading, spacing: 8) {
                    Text("Style")
                        .font(.body.weight(.medium))
                        .foregroundColor(Color("Charcoal"))

                    HStack(spacing: 4) {
                        ForEach(ReminderStyle.allCases, id: \.self) { style in
                            Button(style.label) {
                                store.setReminderStyle(style)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(store.settings.reminderStyle == style ? Color.red : Color(.systemGray6))
                            .foregroundColor(store.settings.reminderStyle == style ? .white : Color("Charcoal"))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Divider().padding(.top, 12)

                // Sound segmented
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sound")
                        .font(.body.weight(.medium))
                        .foregroundColor(Color("Charcoal"))

                    HStack(spacing: 4) {
                        ForEach(SoundMode.allCases, id: \.self) { mode in
                            Button(mode.label) {
                                store.setSoundMode(mode)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(store.settings.soundMode == mode ? Color.red : Color(.systemGray6))
                            .foregroundColor(store.settings.soundMode == mode ? .white : Color("Charcoal"))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Divider().padding(.top, 12)

                // Vibration
                Toggle(isOn: Binding(
                    get: { store.settings.vibrationEnabled },
                    set: { store.setVibration($0) }
                )) {
                    Text("Vibration")
                        .font(.body.weight(.medium))
                }
                .tint(.red)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                RedBand()

                // MARK: - OEM guidance (iOS specific)
                Text("iOS background tips")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    OemItem(
                        title: "Background App Refresh",
                        body: "Go to Settings > General > Background App Refresh. Ensure it's enabled globally and for Retina Guard."
                    )
                    OemItem(
                        title: "Low Power Mode",
                        body: "Low Power Mode disables background refresh. Keep your device charged or disable Low Power Mode for reliable reminders."
                    )
                    OemItem(
                        title: "Notification delivery",
                        body: "Go to Settings > Notifications > Retina Guard. Enable 'Allow Notifications', set to 'Immediate Delivery', and choose a prominent alert style."
                    )
                    OemItem(
                        title: "Focus / Do Not Disturb",
                        body: "If you use Focus modes, add Retina Guard to the 'Allowed Apps' list so break reminders aren't silenced."
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                RedBand()

                // MARK: - Privacy
                Text("Privacy")
                    .font(.title2.bold())
                    .foregroundColor(Color("Charcoal"))
                    .padding(.horizontal, 24)

                Button {
                    store.resetTodayStats()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset today's stats")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color("Charcoal"))
                            Text("Delete completed/skipped/protected counters for today.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Reset")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                Divider().padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .task {
            perms = await PermissionState.read()
        }
    }

    private var exclusionLabel: String {
        let count = store.settings.excludedBundleIDs.count
        return count == 0 ? "No excluded apps" : "\(count) excluded app(s)"
    }
}

struct OemItem: View {
    let title: String
    let body: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(Color("Charcoal"))
            Text(body)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
