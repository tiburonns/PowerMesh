import Foundation

enum PowerMeshStorage {
    static let appGroupIdentifier = "group.com.tiburonns.PowerMesh"
    static let snapshotsKey = "powermesh.cache.snapshots.v1"
    static let historyKey = "powermesh.cache.history.v1"
    static let lastSuccessfulSyncKey = "powermesh.cache.lastSuccessfulSync.v1"

    static var sharedDefaults: UserDefaults {
        #if POWERMESH_LOCAL_ONLY
        return .standard
        #else
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        #endif
    }
}

@MainActor
enum WidgetRefreshBridge {
    static var reloadAll: () -> Void = {}

    static func reload() {
        reloadAll()
    }
}

actor SnapshotCache {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = PowerMeshStorage.sharedDefaults) {
        self.defaults = defaults
    }

    func load() -> [BatterySnapshot] {
        guard let data = defaults.data(forKey: PowerMeshStorage.snapshotsKey),
              let decoded = try? decoder.decode([BatterySnapshot].self, from: data) else {
            return []
        }

        let oldestAllowed = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return decoded
            .filter { $0.isValidForSync && $0.updatedAt >= oldestAllowed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ snapshots: [BatterySnapshot]) {
        let valid = snapshots.filter(\.isValidForSync)
        guard let data = try? encoder.encode(valid) else { return }

        defaults.set(data, forKey: PowerMeshStorage.snapshotsKey)
        let language = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
            ?? AppLanguage.system.rawValue
        defaults.set(language, forKey: AppLanguage.storageKey)

        Task { @MainActor in
            WidgetRefreshBridge.reload()
        }
    }

    func remove(deviceID: String) {
        let filtered = load().filter { $0.id != deviceID }
        save(filtered)
    }

    func loadLastSuccessfulSync() -> Date? {
        defaults.object(forKey: PowerMeshStorage.lastSuccessfulSyncKey) as? Date
    }

    func saveLastSuccessfulSync(_ date: Date) {
        defaults.set(date, forKey: PowerMeshStorage.lastSuccessfulSyncKey)
    }
}

actor BatteryHistoryStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let retention: TimeInterval = 7 * 24 * 60 * 60
    private let minimumSampleInterval: TimeInterval = 5 * 60
    private let maximumPointsPerDevice = 2_016

    init(defaults: UserDefaults = PowerMeshStorage.sharedDefaults) {
        self.defaults = defaults
    }

    func all() -> [String: [BatteryHistoryPoint]] {
        guard let data = defaults.data(forKey: PowerMeshStorage.historyKey),
              let decoded = try? decoder.decode([String: [BatteryHistoryPoint]].self, from: data) else {
            return [:]
        }
        return prune(decoded)
    }

    func history(for deviceID: String) -> [BatteryHistoryPoint] {
        all()[deviceID] ?? []
    }

    func record(_ snapshots: [BatterySnapshot], now: Date = .now) {
        var history = all()
        let oldestAllowed = now.addingTimeInterval(-retention)

        for snapshot in snapshots {
            guard let level = snapshot.level,
                  snapshot.updatedAt >= oldestAllowed else { continue }

            var points = history[snapshot.id] ?? []
            points.removeAll { $0.date < oldestAllowed }

            let candidate = BatteryHistoryPoint(
                deviceID: snapshot.id,
                date: snapshot.updatedAt,
                level: level,
                state: snapshot.state
            )

            if let last = points.last {
                if last.date == candidate.date {
                    continue
                }

                let closeInTime = candidate.date.timeIntervalSince(last.date) < minimumSampleInterval
                let unchanged = last.level == candidate.level && last.state == candidate.state
                if closeInTime && unchanged {
                    continue
                }
            }

            points.append(candidate)
            points.sort { $0.date < $1.date }
            if points.count > maximumPointsPerDevice {
                points.removeFirst(points.count - maximumPointsPerDevice)
            }
            history[snapshot.id] = points
        }

        persist(prune(history, now: now))
    }

    func remove(deviceID: String) {
        var history = all()
        history.removeValue(forKey: deviceID)
        persist(history)
    }

    private func prune(
        _ history: [String: [BatteryHistoryPoint]],
        now: Date = .now
    ) -> [String: [BatteryHistoryPoint]] {
        let oldestAllowed = now.addingTimeInterval(-retention)
        return history.reduce(into: [:]) { result, element in
            let points = element.value
                .filter { $0.date >= oldestAllowed }
                .sorted { $0.date < $1.date }
            if !points.isEmpty {
                result[element.key] = Array(points.suffix(maximumPointsPerDevice))
            }
        }
    }

    private func persist(_ history: [String: [BatteryHistoryPoint]]) {
        guard let data = try? encoder.encode(history) else { return }
        defaults.set(data, forKey: PowerMeshStorage.historyKey)
    }
}
