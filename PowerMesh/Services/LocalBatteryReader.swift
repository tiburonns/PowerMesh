import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import IOKit.ps
#endif

@MainActor
protocol BatteryReading {
    func read() -> BatterySnapshot
}

@MainActor
struct LocalBatteryReader: BatteryReading {
    init() {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #elseif os(watchOS)
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        #endif
    }

    func read() -> BatterySnapshot {
        #if os(iOS)
        let device = UIDevice.current
        let rawLevel = device.batteryLevel
        let kind: DeviceKind = device.userInterfaceIdiom == .pad ? .iPad : .iPhone

        return BatterySnapshot(
            id: DeviceIdentity.id,
            name: DeviceIdentity.name,
            kind: kind,
            level: rawLevel >= 0 ? Int((rawLevel * 100).rounded()) : nil,
            state: map(device.batteryState),
            updatedAt: Date(),
            source: "UIDevice"
        )

        #elseif os(watchOS)
        let device = WKInterfaceDevice.current()
        let rawLevel = device.batteryLevel

        return BatterySnapshot(
            id: DeviceIdentity.id,
            name: DeviceIdentity.name,
            kind: .watch,
            level: rawLevel >= 0 ? Int((rawLevel * 100).rounded()) : nil,
            state: map(device.batteryState),
            updatedAt: Date(),
            source: "WKInterfaceDevice"
        )

        #elseif os(macOS)
        return readMacBattery()

        #else
        return BatterySnapshot(
            id: DeviceIdentity.id,
            name: DeviceIdentity.name,
            kind: .accessory,
            level: nil,
            state: .unknown,
            updatedAt: Date(),
            source: "Unsupported platform"
        )
        #endif
    }

    #if os(iOS)
    private func map(_ state: UIDevice.BatteryState) -> ChargeState {
        switch state {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
    #endif

    #if os(watchOS)
    private func map(_ state: WKInterfaceDeviceBatteryState) -> ChargeState {
        switch state {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
    #endif

    #if os(macOS)
    private func readMacBattery() -> BatterySnapshot {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)
                .takeUnretainedValue() as? [String: Any] else { continue }

            let type = description[kIOPSTypeKey] as? String
            guard type == kIOPSInternalBatteryType else { continue }

            let current = description[kIOPSCurrentCapacityKey] as? Int
            let maximum = description[kIOPSMaxCapacityKey] as? Int
            let charging = description[kIOPSIsChargingKey] as? Bool ?? false
            let charged = description[kIOPSIsChargedKey] as? Bool ?? false

            let level: Int? = {
                guard let current else { return nil }
                guard let maximum, maximum > 0 else {
                    return max(0, min(100, current))
                }
                return max(0, min(100, Int((Double(current) / Double(maximum) * 100).rounded())))
            }()

            let state: ChargeState = charged ? .full : (charging ? .charging : .unplugged)

            return BatterySnapshot(
                id: DeviceIdentity.id,
                name: DeviceIdentity.name,
                kind: .mac,
                level: level,
                state: state,
                updatedAt: Date(),
                source: "IOKit"
            )
        }

        return BatterySnapshot(
            id: DeviceIdentity.id,
            name: DeviceIdentity.name,
            kind: .mac,
            level: nil,
            state: .externalPower,
            updatedAt: Date(),
            source: "IOKit"
        )
    }
    #endif
}
