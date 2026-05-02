import SwiftUI
import BackgroundTasks

@main
struct RetinaGuardApp: App {

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
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.retinaguard.refresh",
            using: nil
        ) { task in
            AlarmScheduler.shared.onBreakDue()
            task.setTaskCompleted(success: true)
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

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        return .newData
    }
}
