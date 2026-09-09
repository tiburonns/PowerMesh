import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @State private var showingSettings = false

    private let columns = [
        GridItem(.adaptive(minimum: 190), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = store.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.snapshots) { snapshot in
                            BatteryCard(snapshot: snapshot)
                        }
                    }

                    if store.snapshots.isEmpty && !store.isRefreshing {
                        VStack(spacing: 10) {
                            Image(systemName: "battery.0")
                                .font(.largeTitle)
                            Text("Sin dispositivos todavía")
                                .font(.headline)
                            Text("Instala y abre PowerMesh en tus dispositivos Apple con la misma cuenta de iCloud.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding()
            }
            .navigationTitle("Baterías")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        Task { await store.refreshNow() }
                    } label: {
                        if store.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(store.isRefreshing)
                    .accessibilityLabel("Actualizar")

                    #if !os(watchOS)
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Configuración")
                    #endif
                }
            }
            #if !os(watchOS)
            .refreshable {
                await store.refreshNow()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            #endif
            .task {
                store.start()
            }
        }
    }
}
