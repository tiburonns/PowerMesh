import Combine
import Foundation

enum DashboardSyncIssue: Equatable {
    case iCloudUnavailable
    case detail(String)

    func message(in language: AppLanguage) -> String {
        switch self {
        case .iCloudUnavailable: return language.text(.iCloudUnavailable)
        case .detail(let detail): return "\(language.text(.syncError)) (\(detail))"
        }
    }
}

@MainActor
final class BatteryDashboardStore: ObservableObject {
    @Published private(set) var snapshots: [BatterySnapshot] = []
    @Published private(set) var historyByDevice: [String: [BatteryHistoryPoint]] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var syncIssue: DashboardSyncIssue?
    @Published private(set) var lastSuccessfulSync: Date?
    @Published var localDeviceName: String = DeviceIdentity.name

    private let cloud: any BatteryCloudStore
    private let batteryReader: any BatteryReading
    private let remoteRefreshInterval: TimeInterval
    private let cache: SnapshotCache
    private let historyStore: BatteryHistoryStore
    private let accessoryScanner: AccessoryBatteryScanner

    private var reportingTask: Task<Void, Never>?
    private var lastPublished: BatterySnapshot?
    private var localSnapshot: BatterySnapshot?
    private var lastRemoteRefresh: Date?

    init(
        cloud: any BatteryCloudStore = CloudBatteryStore(),
        batteryReader: any BatteryReading = LocalBatteryReader(),
        remoteRefreshInterval: TimeInterval = 5 * 60,
        cache: SnapshotCache = SnapshotCache(),
        historyStore: BatteryHistoryStore = BatteryHistoryStore(),
        accessoryScanner: AccessoryBatteryScanner = AccessoryBatteryScanner()
    ) {
        self.cloud = cloud
        self.batteryReader = batteryReader
        self.remoteRefreshInterval = remoteRefreshInterval
        self.cache = cache
        self.historyStore = historyStore
        self.accessoryScanner = accessoryScanner
    }

    deinit {
        reportingTask?.cancel()
    }

    func start() {
        guard reportingTask == nil else { return }

        PowerMeshBackgroundRouter.shared.install { [weak self] in
            guard let self else { return false }
            return await self.refreshForBackground()
        }

        accessoryScanner.onSnapshot = { [weak self] snapshot in
            self?.ingestAccessory(snapshot)
        }
        if accessoryScanner.isEnabled {
            accessoryScanner.start()
        }

        reportingTask = Task { [weak self] in
            guard let self else { return }
            await self.restoreCachedState()
            await self.prepareRemoteChanges()
            await self.refreshNow(forceUpload: true)

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }

                _ = await self.reportLocalIfNeeded(force: false)
                if self.shouldRefreshRemote {
                    _ = await self.loadRemote()
                }
            }
        }
    }

    func refreshNow(forceUpload: Bool = true) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        if accessoryScanner.isEnabled {
            accessoryScanner.rescan()
        }

        _ = await reportLocalIfNeeded(force: forceUpload)
        _ = await loadRemote()
    }

    func refreshForBackground() async -> Bool {
        let uploadSucceeded = await reportLocalIfNeeded(force: false)
        let downloadSucceeded = await loadRemote()
        #if os(iOS)
        BackgroundRefreshCoordinator.schedule()
        #elseif os(watchOS)
        WatchBackgroundRefreshCoordinator.schedule()
        #endif
        return uploadSucceeded && downloadSucceeded
    }

    func refreshSharedPresentation() async {
        await cache.save(snapshots)
    }

    func setAccessoryScanning(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: AccessoryBatterySettings.enabledKey)
        if enabled {
            accessoryScanner.start()
        } else {
            accessoryScanner.stop()
        }
    }

    func renameLocalDevice(to newName: String) async {
        DeviceIdentity.name = newName
        localDeviceName = DeviceIdentity.name
        _ = await reportLocalIfNeeded(force: true)
        _ = await loadRemote()
    }

    func forgetDevice(id: String) async {
        guard id != DeviceIdentity.id else { return }

        do {
            try await cloud.delete(deviceID: id)
            snapshots.removeAll { $0.id == id }
            await cache.remove(deviceID: id)
            await historyStore.remove(deviceID: id)
            historyByDevice = await historyStore.all()
            syncIssue = nil
        } catch {
            syncIssue = issue(for: error)
        }
    }

    func history(for deviceID: String) -> [BatteryHistoryPoint] {
        historyByDevice[deviceID] ?? []
    }

    private var shouldRefreshRemote: Bool {
        guard let lastRemoteRefresh else { return true }
        return Date().timeIntervalSince(lastRemoteRefresh) >= remoteRefreshInterval
    }

    private func restoreCachedState() async {
        let cached = await cache.load()
        if !cached.isEmpty {
            snapshots = cached
        }
        historyByDevice = await historyStore.all()
        lastSuccessfulSync = await cache.loadLastSuccessfulSync()
    }

    private func prepareRemoteChanges() async {
        do {
            try await cloud.prepareForRemoteChanges()
        } catch {
            syncIssue = issue(for: error)
        }
    }

    private func reportLocalIfNeeded(force: Bool) async -> Bool {
        let current = batteryReader.read()
        localSnapshot = current
        merge(current)
        await persistObservedState()

        let shouldPublish: Bool
        if force || lastPublished == nil {
            shouldPublish = true
        } else if let previous = lastPublished {
            let levelChanged = previous.level != current.level
            let stateChanged = previous.state != current.state
            let nameChanged = previous.name != current.name
            let periodicHeartbeat = Date().timeIntervalSince(previous.updatedAt) >= 15 * 60
            shouldPublish = levelChanged || stateChanged || nameChanged || periodicHeartbeat
        } else {
            shouldPublish = true
        }

        guard shouldPublish else { return true }

        do {
            try await cloud.upsert(current)
            lastPublished = current
            syncIssue = nil
            return true
        } catch {
            syncIssue = issue(for: error)
            return false
        }
    }

    private func loadRemote() async -> Bool {
        do {
            let remote = try await cloud.fetchAll()
            snapshots = BatterySnapshotReconciler.merge(remote: remote, local: localSnapshot)
            lastRemoteRefresh = .now
            let syncDate = Date()
            lastSuccessfulSync = syncDate
            await cache.saveLastSuccessfulSync(syncDate)
            syncIssue = nil
            await persistObservedState()
            return true
        } catch {
            if let localSnapshot { merge(localSnapshot) }
            await persistObservedState()
            syncIssue = issue(for: error)
            return false
        }
    }

    private func ingestAccessory(_ snapshot: BatterySnapshot) {
        merge(snapshot)

        Task { [weak self] in
            guard let self else { return }
            await self.persistObservedState()

            do {
                try await self.cloud.upsert(snapshot)
                self.syncIssue = nil
            } catch let error as CloudBatteryStoreError
                where error == .iCloudUnavailable {
                // Keep the local accessory reading even when CloudKit is unavailable.
            } catch {
                self.syncIssue = self.issue(for: error)
            }
        }
    }

    private func persistObservedState() async {
        await cache.save(snapshots)
        await historyStore.record(snapshots)
        historyByDevice = await historyStore.all()

        let raw = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        let language = raw.flatMap(AppLanguage.init(rawValue:)) ?? .system
        await BatteryNotificationService.evaluate(
            snapshots: snapshots,
            language: language
        )
    }

    private func issue(for error: Error) -> DashboardSyncIssue {
        if let cloudError = error as? CloudBatteryStoreError,
           cloudError == .iCloudUnavailable {
            return .iCloudUnavailable
        }
        return .detail(error.localizedDescription)
    }

    private func merge(_ snapshot: BatterySnapshot) {
        if let index = snapshots.firstIndex(where: { $0.id == snapshot.id }) {
            snapshots[index] = snapshot
        } else {
            snapshots.append(snapshot)
        }
        snapshots.sort { $0.updatedAt > $1.updatedAt }
    }
}
