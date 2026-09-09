import SwiftUI

#if !os(watchOS)
struct SettingsView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Este dispositivo") {
                    TextField("Nombre", text: $draftName)
                    Text("El nombre se guarda localmente y se publica únicamente en tu base privada de CloudKit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Configuración")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
