import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: PreferencesStore

    var body: some View {
        if !store.settings.onboardingDone {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var store: PreferencesStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "clock") }
                .tag(0)

            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(.red)
    }
}
