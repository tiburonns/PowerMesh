import Combine
import Foundation

@MainActor
final class BatteryDashboardStore: ObservableObject {
    @Published private(set) var snapshots: [BatterySnapshot] = []
    @Published private(set) var isRefreshing = false
    @Published var errorDetail: String?
    @Published var localDeviceName: String = DeviceIdentity.name

    private let cloud = CloudBatteryStore()
    private let batteryReader = LocalBatteryReader()
    private let remoteRefreshInterval: TimeInterval = 5 * 60

    private var reportingTask: Task<Void, Never>?
    private var lastPublished: BatterySnapshot?
    private var localSnapshot: BatterySnapshot?
    private var lastRemoteRefresh: Date?

    func start() {
        guard reportingTask == nil else { return }

        reportingTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshNow(forceUpload: true)

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }

                await self.reportLocalIfNeeded(force: false)

                if self.shouldRefreshRemote {
                    await self.loadRemote()
                }
            }
        }
    }

    func refreshNow(forceUpload: Bool = true) async {
        isRefreshing = true
        defer { isRefreshing = false }

        await reportLocalIfNeeded(force: forceUpload)
        await loadRemote()
    }

    func renameLocalDevice(to newName: String) async {
        DeviceIdentity.name = newName
        localDeviceName = DeviceIdentity.name
        await reportLocalIfNeeded(force: true)
        await loadRemote()
    }

    private var shouldRefreshRemote: Bool {
        guard let lastRemoteRefresh else { return true }
        return Date().timeIntervalSince(lastRemoteRefresh) >= remoteRefreshInterval
    }

    private func reportLocalIfNeeded(force: Bool) async {
        let current = batteryReader.read()
        localSnapshot = current
        merge(current)

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

        guard shouldPublish else { return }

        do {
            try await cloud.upsert(current)
            lastPublished = current
            errorDetail = nil
        } catch {
            errorDetail = error.localizedDescription
        }
    }

    private func loadRemote() async {
        do {
            let remote = try await cloud.fetchAll()
            var reconciled = Dictionary(
                uniqueKeysWithValues: remote.map { ($0.id, $0) }
            )

            // The device currently running PowerMesh is authoritative for its
            // own battery state. CloudKit may lag immediately after an upload.
            if let localSnapshot {
                reconciled[localSnapshot.id] = localSnapshot
            }

            snapshots = reconciled.values.sorted { $0.updatedAt > $1.updatedAt }
            lastRemoteRefresh = .now
            errorDetail = nil
        } catch {
            // Keep the last good dashboard and the current local reading rather
            // than replacing everything with an incomplete/failed cloud fetch.
            if let localSnapshot {
                merge(localSnapshot)
            }
            errorDetail = error.localizedDescription
        }
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
