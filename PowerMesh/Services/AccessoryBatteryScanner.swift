import CoreBluetooth
import Foundation

enum AccessoryBatterySettings {
    static let enabledKey = "powermesh.accessories.bluetooth.enabled"
}

@MainActor
final class AccessoryBatteryScanner: NSObject {
    var onSnapshot: ((BatterySnapshot) -> Void)?

    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var stopScanTask: Task<Void, Never>?

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AccessoryBatterySettings.enabledKey)
    }

    func start() {
        guard isEnabled else { return }

        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        } else {
            scanIfReady()
        }
    }

    func stop() {
        stopScanTask?.cancel()
        stopScanTask = nil
        central?.stopScan()

        for peripheral in peripherals.values where peripheral.state == .connected {
            central?.cancelPeripheralConnection(peripheral)
        }
        peripherals.removeAll()
    }

    func rescan() {
        guard isEnabled else { return }
        start()
        scanIfReady()
    }

    private func scanIfReady() {
        guard let central, central.state == .poweredOn else { return }

        stopScanTask?.cancel()

        for peripheral in central.retrieveConnectedPeripherals(
            withServices: [CBUUID(string: "180F")]
        ) {
            observe(peripheral)
        }

        central.scanForPeripherals(
            withServices: [CBUUID(string: "180F")],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        stopScanTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            self?.central?.stopScan()
        }
    }

    private func observe(_ peripheral: CBPeripheral) {
        peripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self

        switch peripheral.state {
        case .connected:
            peripheral.discoverServices([CBUUID(string: "180F")])
        case .disconnected:
            central?.connect(peripheral)
        default:
            break
        }
    }

    private func publish(_ level: Int, from peripheral: CBPeripheral) {
        let safeLevel = min(100, max(0, level))
        let name = peripheral.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawLanguage = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        let language = rawLanguage.flatMap(AppLanguage.init(rawValue:)) ?? .system
        let fallbackName = language.text(.bluetoothAccessoryDefaultName)
        let displayName = name.flatMap { $0.isEmpty ? nil : $0 } ?? fallbackName
        let snapshot = BatterySnapshot(
            id: "ble-\(peripheral.identifier.uuidString.lowercased())",
            name: displayName,
            kind: .accessory,
            level: safeLevel,
            state: .unknown,
            updatedAt: .now,
            source: "Bluetooth Battery Service"
        )
        onSnapshot?(snapshot)
    }
}

extension AccessoryBatteryScanner: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if central.state == .poweredOn {
                self.scanIfReady()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor [weak self] in
            self?.observe(peripheral)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.peripherals[peripheral.identifier] = peripheral
            peripheral.delegate = self
            peripheral.discoverServices([CBUUID(string: "180F")])
        }
    }
}

extension AccessoryBatteryScanner: CBPeripheralDelegate {
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard error == nil else { return }
        Task { @MainActor in
            peripheral.services?
                .filter { $0.uuid == CBUUID(string: "180F") }
                .forEach {
                    peripheral.discoverCharacteristics(
                        [CBUUID(string: "2A19")],
                        for: $0
                    )
                }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else { return }
        Task { @MainActor in
            service.characteristics?
                .filter { $0.uuid == CBUUID(string: "2A19") }
                .forEach { characteristic in
                    peripheral.readValue(for: characteristic)
                    if characteristic.properties.contains(.notify) {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
              characteristic.uuid == CBUUID(string: "2A19"),
              let value = characteristic.value?.first else { return }

        Task { @MainActor [weak self] in
            self?.publish(Int(value), from: peripheral)
        }
    }
}
