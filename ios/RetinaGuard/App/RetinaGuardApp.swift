import SwiftUI
import BackgroundTasks

@main
struct RetinaGuardApp: App {

    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = PreferencesStore.shared

    init() {
        NotificationManager.shared.configure()
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        AlarmScheduler.shared.rescheduleOnForeground()
                        LiveActivityManager.shared.syncFromStore(store)
                    }
                }
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.retinaguard.refresh",
            using: nil
        ) { task in
            Task { @MainActor in
                AlarmScheduler.shared.onBreakDue()
                task.setTaskCompleted(success: true)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
}
