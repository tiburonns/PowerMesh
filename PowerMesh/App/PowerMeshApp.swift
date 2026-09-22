import SwiftUI
#if os(watchOS)
import WatchKit
#endif
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
    #elseif os(watchOS)
    @WKApplicationDelegateAdaptor(PowerMeshWatchAppDelegate.self) private var appDelegate
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
        #if os(watchOS)
        WindowGroup {
            dashboard
        }
        .backgroundTask(.appRefresh(WatchBackgroundRefreshCoordinator.identifier)) { _ in
            _ = await store.refreshForBackground()
            await MainActor.run {
                WatchBackgroundRefreshCoordinator.schedule()
            }
        }
        #else
        WindowGroup {
            dashboard
        }
        #endif

        #if os(macOS)
        MenuBarExtra("PowerMesh", systemImage: "battery.100") {
            CompactMenuView()
                .environmentObject(store)
                .environment(\.appLanguage, selectedLanguage)
                .environment(\.locale, selectedLanguage.locale)
        }
        #endif
    }

    private var dashboard: some View {
        DashboardView()
            .environmentObject(store)
            .environment(\.appLanguage, selectedLanguage)
            .environment(\.locale, selectedLanguage.locale)
            .onChange(of: languagePreference) { _, _ in
                Task { await store.refreshSharedPresentation() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    #if os(iOS)
                    BackgroundRefreshCoordinator.schedule()
                    #elseif os(watchOS)
                    WatchBackgroundRefreshCoordinator.schedule()
                    #endif
                }
            }
    }
}
