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
