import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language
    @State private var showingSettings = false

    private let columns = [
        GridItem(.adaptive(minimum: 190), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let detail = store.errorDetail {
                        Text("\(language.text(.syncError)) (\(detail))")
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
                            Text(language.text(.noDevicesTitle))
                                .font(.headline)
                            Text(language.text(.noDevicesMessage))
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
            .navigationTitle(language.text(.batteriesTitle))
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
                    .accessibilityLabel(language.text(.refresh))

                    #if !os(watchOS)
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(language.text(.settings))
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
