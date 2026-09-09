import SwiftUI

@main
struct PowerMeshApp: App {
    @StateObject private var store = BatteryDashboardStore()
    @AppStorage(AppLanguage.storageKey) private var languagePreference = AppLanguage.system.rawValue

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languagePreference) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
                .environment(\.appLanguage, selectedLanguage)
                .environment(\.locale, selectedLanguage.locale)
        }

        #if os(macOS)
        MenuBarExtra("PowerMesh", systemImage: "battery.100") {
            CompactMenuView()
                .environmentObject(store)
                .environment(\.appLanguage, selectedLanguage)
                .environment(\.locale, selectedLanguage.locale)
        }
        #endif
    }
}
