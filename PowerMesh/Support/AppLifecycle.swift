import CloudKit
import Foundation

@MainActor
final class PowerMeshBackgroundRouter {
    static let shared = PowerMeshBackgroundRouter()

    private var refreshHandler: (() async -> Bool)?

    private init() {}

    func install(_ handler: @escaping () async -> Bool) {
        refreshHandler = handler
    }

    func refresh() async -> Bool {
        if let refreshHandler {
            return await refreshHandler()
        }

        // A silent CloudKit notification can launch the app before SwiftUI
        // creates the dashboard task. Use a minimal store as a safe fallback.
        let fallbackStore = BatteryDashboardStore()
        return await fallbackStore.refreshForBackground()
    }
}

#if os(iOS)
import UIKit

final class PowerMeshAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if !POWERMESH_LOCAL_ONLY
        application.registerForRemoteNotifications()
        #endif
        BackgroundRefreshCoordinator.register()
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            return .noData
        }

        return await PowerMeshBackgroundRouter.shared.refresh() ? .newData : .failed
    }
}
#endif

#if os(macOS)
import AppKit

final class PowerMeshMacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if !POWERMESH_LOCAL_ONLY
        NSApplication.shared.registerForRemoteNotifications()
        #endif
    }

    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        let payload = Dictionary(uniqueKeysWithValues: userInfo.map {
            (AnyHashable($0.key), $0.value)
        })
        guard CKNotification(fromRemoteNotificationDictionary: payload) != nil else { return }
        Task { @MainActor in
            _ = await PowerMeshBackgroundRouter.shared.refresh()
        }
    }
}
#endif


#if os(watchOS)
import WatchKit

final class PowerMeshWatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        #if !POWERMESH_LOCAL_ONLY
        WKApplication.shared().registerForRemoteNotifications()
        #endif
    }

    nonisolated func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any]
    ) async -> WKBackgroundFetchResult {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            return .noData
        }

        return await PowerMeshBackgroundRouter.shared.refresh() ? .newData : .failed
    }
}
#endif
