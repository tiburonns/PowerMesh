import Foundation

enum DeviceKind: String, Codable, CaseIterable, Sendable {
    case iPhone
    case iPad
    case mac
    case watch
    case accessory

    var displayName: String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .mac: return "Mac"
        case .watch: return "Apple Watch"
        case .accessory: return "Accesorio"
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

enum ChargeState: String, Codable, Sendable {
    case charging
    case unplugged
    case full
    case externalPower
    case unknown

    var displayName: String {
        switch self {
        case .charging: return "Cargando"
        case .unplugged: return "Con batería"
        case .full: return "Carga completa"
        case .externalPower: return "Alimentación externa"
        case .unknown: return "Estado desconocido"
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
