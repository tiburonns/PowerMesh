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

    var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > 30 * 60
    }
}
