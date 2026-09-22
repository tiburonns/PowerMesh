import Foundation

struct BatteryHistoryPoint: Identifiable, Codable, Hashable, Sendable {
    var deviceID: String
    var date: Date
    var level: Int
    var state: ChargeState

    var id: String {
        "\(deviceID)-\(date.timeIntervalSince1970)"
    }
}

struct BatteryTrend: Hashable, Sendable {
    let percentPerHour: Double
    let sampleDuration: TimeInterval

    var isStable: Bool {
        abs(percentPerHour) < 0.2
    }
}

enum BatteryHistoryAnalyzer {
    static func trend(
        points: [BatteryHistoryPoint],
        now: Date = .now,
        window: TimeInterval = 6 * 60 * 60,
        minimumDuration: TimeInterval = 15 * 60
    ) -> BatteryTrend? {
        let sorted = points.sorted { $0.date < $1.date }
        guard let latest = sorted.last else { return nil }

        let lowerBound = max(
            latest.date.addingTimeInterval(-window),
            now.addingTimeInterval(-window)
        )

        guard let baseline = sorted.first(where: {
            $0.date >= lowerBound
                && latest.date.timeIntervalSince($0.date) >= minimumDuration
        }) else {
            return nil
        }

        let duration = latest.date.timeIntervalSince(baseline.date)
        guard duration >= minimumDuration else { return nil }

        let hours = duration / 3_600
        return BatteryTrend(
            percentPerHour: Double(latest.level - baseline.level) / hours,
            sampleDuration: duration
        )
    }
}

enum SnapshotAvailability: String, Codable, Hashable, Sendable {
    case live
    case recent
    case stale
    case offline

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .live: return language.text(.statusLive)
        case .recent: return language.text(.statusRecent)
        case .stale: return language.text(.statusStale)
        case .offline: return language.text(.statusOffline)
        }
    }
}
