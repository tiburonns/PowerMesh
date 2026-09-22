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
            // CoreBluetooth delivers callbacks on the queue supplied here.
            // Keeping that queue on the main actor lets the scanner own all
            // non-Sendable CoreBluetooth objects without actor hops.
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

extension AccessoryBatteryScanner: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanIfReady()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        observe(peripheral)
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "180F")])
    }
}

extension AccessoryBatteryScanner: @preconcurrency CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard error == nil else { return }

        peripheral.services?
            .filter { $0.uuid == CBUUID(string: "180F") }
            .forEach {
                peripheral.discoverCharacteristics(
                    [CBUUID(string: "2A19")],
                    for: $0
                )
            }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else { return }

        service.characteristics?
            .filter { $0.uuid == CBUUID(string: "2A19") }
            .forEach { characteristic in
                peripheral.readValue(for: characteristic)
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
              characteristic.uuid == CBUUID(string: "2A19"),
              let value = characteristic.value?.first else { return }

        publish(Int(value), from: peripheral)
    }
}
