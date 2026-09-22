import CoreBluetooth
import Foundation

enum AccessoryBatterySettings {
    static let enabledKey = "powermesh.accessories.bluetooth.enabled"
}

@MainActor
final class AccessoryBatteryScanner: NSObject {
    private static let batteryService = CBUUID(string: "180F")
    private static let batteryLevelCharacteristic = CBUUID(string: "2A19")

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
            withServices: [Self.batteryService]
        ) {
            observe(peripheral)
        }

        central.scanForPeripherals(
            withServices: [Self.batteryService],
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
            peripheral.discoverServices([Self.batteryService])
        case .disconnected:
            central?.connect(peripheral)
        default:
            break
        }
    }

    private func publish(_ level: Int, from peripheral: CBPeripheral) {
        let safeLevel = min(100, max(0, level))
        let name = peripheral.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = BatterySnapshot(
            id: "ble-\(peripheral.identifier.uuidString.lowercased())",
            name: (name?.isEmpty == false ? name! : "Bluetooth Accessory"),
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
            peripheral.discoverServices([Self.batteryService])
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
                .filter { $0.uuid == Self.batteryService }
                .forEach {
                    peripheral.discoverCharacteristics(
                        [Self.batteryLevelCharacteristic],
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
                .filter { $0.uuid == Self.batteryLevelCharacteristic }
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
              characteristic.uuid == Self.batteryLevelCharacteristic,
              let value = characteristic.value?.first else { return }

        Task { @MainActor [weak self] in
            self?.publish(Int(value), from: peripheral)
        }
    }
}
