import Foundation

#if os(iOS)
import BackgroundTasks

@MainActor
enum BackgroundRefreshCoordinator {
    static let identifier = "com.tiburonns.PowerMesh.refresh"
    private static var didRegister = false

    static func register() {
        #if POWERMESH_LOCAL_ONLY
        return
        #else
        guard !didRegister else { return }
        guard let permitted = Bundle.main.object(
            forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers"
        ) as? [String],
        permitted.contains(identifier) else {
            return
        }

        didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            schedule()
            let worker = Task { @MainActor in
                let success = await PowerMeshBackgroundRouter.shared.refresh()
                guard !Task.isCancelled else { return }
                refreshTask.setTaskCompleted(success: success)
            }
            refreshTask.expirationHandler = {
                worker.cancel()
            }
        }
        #endif
    }

    static func schedule() {
        #if POWERMESH_LOCAL_ONLY
        return
        #else
        guard didRegister else { return }

        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Scheduling is opportunistic; a failure must not affect foreground sync.
        }
        #endif
    }
}
#endif

#if os(watchOS)
import WatchKit

@MainActor
enum WatchBackgroundRefreshCoordinator {
    static let identifier = "powermesh-refresh"

    static func schedule() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date(timeIntervalSinceNow: 15 * 60),
            userInfo: identifier as NSString
        ) { _ in
            // watchOS owns the final execution time and budget.
        }
    }
}
#endif
