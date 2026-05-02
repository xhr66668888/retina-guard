import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var store: PreferencesStore

    private let dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SCHEDULE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color("Charcoal"))
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                // Daily schedule toggle
                Toggle(isOn: Binding(
                    get: { store.settings.dailyScheduleEnabled },
                    set: { store.setDailySchedule($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily schedule")
                            .font(.body.weight(.medium))
                        Text("Only run during specific hours on active days.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.red)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Divider().padding(.top, 16)

                // Active days
                if store.settings.dailyScheduleEnabled {
                    Text("ACTIVE DAYS")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { i in
                            Button(dayNames[i]) {
                                var mask = store.settings.activeDaysMask
                                mask ^= (1 << i)
                                store.setActiveDaysMask(mask)
                            }
                            .frame(width: 40, height: 40)
                            .background(isDayActive(i) ? Color.red : Color(.systemGray6))
                            .foregroundColor(isDayActive(i) ? .white : Color("Charcoal"))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    HStack {
                        Text("Active hours")
                            .font(.subheadline)
                        Spacer()
                        Text("09:00 – 18:00")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                    Divider().padding(.top, 16)
                }

                // Quiet hours
                Toggle(isOn: Binding(
                    get: { store.settings.quietHoursEnabled },
                    set: { store.setQuietHours($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quiet hours")
                            .font(.body.weight(.medium))
                        Text("Pause reminders from 22:00 to 08:00.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.red)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                if store.settings.quietHoursEnabled {
                    HStack {
                        Text("Quiet period")
                            .font(.subheadline)
                        Spacer()
                        Text("22:00 – 08:00")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                Divider().padding(.top, 16)
            }
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }

    private func isDayActive(_ index: Int) -> Bool {
        store.settings.activeDaysMask & (1 << index) != 0
    }
}
