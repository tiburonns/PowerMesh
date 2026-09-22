import SwiftUI

#if !os(watchOS)
struct SettingsView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languagePreference = AppLanguage.system.rawValue
    @AppStorage(BatteryAlertSettings.enabledKey) private var lowBatteryAlerts = false
    @AppStorage(BatteryAlertSettings.thresholdKey) private var lowBatteryThreshold = BatteryAlertSettings.defaultThreshold
    @AppStorage(AccessoryBatterySettings.enabledKey) private var bluetoothAccessories = false
    @State private var draftName = ""
    @State private var notificationPermissionDenied = false

    private var remoteDevices: [BatterySnapshot] {
        store.snapshots.filter { $0.id != DeviceIdentity.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(language.text(.languageSection)) {
                    Picker(language.text(.language), selection: $languagePreference) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.optionTitle(in: language)).tag(option.rawValue)
                        }
                    }
                    Text(language.text(.languageHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.thisDevice)) {
                    TextField(language.text(.name), text: $draftName)
                    Text(language.text(.deviceNameHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.accessoriesSection)) {
                    Toggle(
                        language.text(.bluetoothAccessories),
                        isOn: $bluetoothAccessories
                    )
                    Text(language.text(.bluetoothAccessoriesHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.alertsSection)) {
                    Toggle(language.text(.lowBatteryAlerts), isOn: $lowBatteryAlerts)

                    Stepper(value: $lowBatteryThreshold, in: 5...50, step: 5) {
                        HStack {
                            Text(language.text(.lowBatteryThreshold))
                            Spacer()
                            Text("\(lowBatteryThreshold)%").monospacedDigit()
                        }
                    }
                    .disabled(!lowBatteryAlerts)

                    Text(language.text(.lowBatteryAlertsHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if notificationPermissionDenied {
                        Text(language.text(.notificationPermissionDenied))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(language.text(.syncSection)) {
                    HStack {
                        Text(language.text(.lastSync))
                        Spacer()
                        if let date = store.lastSuccessfulSync {
                            Text(date, style: .relative)
                        } else {
                            Text(language.text(.never))
                        }
                    }
                    Text(language.text(.backgroundSyncHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !remoteDevices.isEmpty {
                    Section(language.text(.knownDevices)) {
                        ForEach(remoteDevices) { snapshot in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(snapshot.name)
                                    Text(snapshot.updatedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(language.text(.forgetDevice), role: .destructive) {
                                    Task { await store.forgetDevice(id: snapshot.id) }
                                }
                            }
                        }
                        Text(language.text(.knownDevicesHelp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(language.text(.settings))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.save)) {
                        Task {
                            await store.renameLocalDevice(to: draftName)
                            dismiss()
                        }
                    }
                }
            }
            .onAppear { draftName = store.localDeviceName }
            .onChange(of: bluetoothAccessories) { _, enabled in
                store.setAccessoryScanning(enabled: enabled)
            }
            .onChange(of: lowBatteryAlerts) { _, enabled in
                guard enabled else { return }
                Task {
                    let granted = await BatteryNotificationService.requestAuthorization()
                    await MainActor.run {
                        notificationPermissionDenied = !granted
                        if !granted { lowBatteryAlerts = false }
                    }
                }
            }
        }
    }
}
#endif
