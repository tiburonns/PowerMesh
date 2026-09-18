import SwiftUI

#if !os(watchOS)
struct SettingsView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languagePreference = AppLanguage.system.rawValue
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(language.text(.languageSection)) {
                    Picker(language.text(.language), selection: $languagePreference) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.optionTitle(in: language))
                                .tag(option.rawValue)
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

                let remoteDevices = store.snapshots.filter { $0.id != DeviceIdentity.id }
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
                                    Task {
                                        await store.forgetDevice(id: snapshot.id)
                                    }
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
        }
    }
}
#endif
