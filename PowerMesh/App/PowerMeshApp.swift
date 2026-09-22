import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
struct PowerMeshApp: App {
    @StateObject private var store = BatteryDashboardStore()
    @AppStorage(AppLanguage.storageKey) private var languagePreference = AppLanguage.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    #if os(iOS)
    @UIApplicationDelegateAdaptor(PowerMeshAppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(PowerMeshMacAppDelegate.self) private var appDelegate
    #endif

    init() {
        #if canImport(WidgetKit)
        WidgetRefreshBridge.reloadAll = {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languagePreference) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
                .environment(\.appLanguage, selectedLanguage)
                .environment(\.locale, selectedLanguage.locale)
                .onChange(of: scenePhase) { _, phase in
                    #if os(iOS)
                    if phase == .background {
                        BackgroundRefreshCoordinator.schedule()
                    }
                    #endif
                }
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
