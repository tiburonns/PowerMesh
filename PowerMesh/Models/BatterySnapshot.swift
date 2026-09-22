import Foundation

enum DeviceKind: String, Codable, CaseIterable, Hashable, Sendable {
    case iPhone
    case iPad
    case mac
    case watch
    case accessory

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .mac: return "Mac"
        case .watch: return "Apple Watch"
        case .accessory: return language.text(.accessory)
        }
    }

    var systemImage: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "laptopcomputer"
        case .watch: return "applewatch"
        case .accessory: return "headphones"
        }
    }
}

enum ChargeState: String, Codable, Hashable, Sendable {
    case charging
    case unplugged
    case full
    case externalPower
    case unknown

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .charging: return language.text(.charging)
        case .unplugged: return language.text(.chargeOnBattery)
        case .full: return language.text(.chargeFull)
        case .externalPower: return language.text(.chargeExternalPower)
        case .unknown: return language.text(.chargeUnknown)
        }
    }
}

struct BatterySnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var kind: DeviceKind
    var level: Int?
    var state: ChargeState
    var updatedAt: Date
    var source: String

    var isValidForSync: Bool {
        let cleanID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanID.isEmpty,
              cleanID.count <= 256,
              !cleanName.isEmpty,
              cleanName.count <= 256,
              !cleanSource.isEmpty,
              cleanSource.count <= 128 else {
            return false
        }

        if let level, !(0...100).contains(level) {
            return false
        }

        return true
    }

    var availability: SnapshotAvailability {
        availability(at: .now)
    }

    func availability(at now: Date) -> SnapshotAvailability {
        let age = max(0, now.timeIntervalSince(updatedAt))
        switch age {
        case ..<(5 * 60): return .live
        case ..<(30 * 60): return .recent
        case ..<(2 * 60 * 60): return .stale
        default: return .offline
        }
    }

    var isStale: Bool {
        isStale(at: .now)
    }

    func isStale(
        at now: Date,
        threshold: TimeInterval = 30 * 60
    ) -> Bool {
        now.timeIntervalSince(updatedAt) > threshold
    }
}

enum BatterySnapshotReconciler {
    static func merge(
        remote: [BatterySnapshot],
        local: BatterySnapshot?
    ) -> [BatterySnapshot] {
        var byID: [String: BatterySnapshot] = [:]

        for snapshot in remote where snapshot.isValidForSync {
            if let existing = byID[snapshot.id] {
                if snapshot.updatedAt > existing.updatedAt {
                    byID[snapshot.id] = snapshot
                }
            } else {
                byID[snapshot.id] = snapshot
            }
        }

        if let local, local.isValidForSync {
            byID[local.id] = local
        }

        return byID.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.id < rhs.id
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}
