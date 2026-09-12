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
    private var reportingTask: Task<Void, Never>?
    private var lastPublished: BatterySnapshot?

    func start() {
        guard reportingTask == nil else { return }

        reportingTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshNow(forceUpload: true)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }

                await self.reportLocalIfNeeded(force: false)

                // Pull remote data less aggressively than local battery checks.
                if Int(Date().timeIntervalSince1970) % (5 * 60) < 60 {
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

    private func reportLocalIfNeeded(force: Bool) async {
        let current = batteryReader.read()
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
            snapshots = remote
            errorDetail = nil
        } catch {
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
