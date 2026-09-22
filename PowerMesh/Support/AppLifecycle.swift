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
        await refreshHandler?() ?? false
    }
}

#if os(iOS)
import UIKit

final class PowerMeshAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        Task { @MainActor in
            BackgroundRefreshCoordinator.register()
        }
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
