import SwiftUI

@main
struct PowerMeshApp: App {
    @StateObject private var store = BatteryDashboardStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
        }

        #if os(macOS)
        MenuBarExtra("PowerMesh", systemImage: "battery.100") {
            CompactMenuView()
                .environmentObject(store)
        }
        #endif
    }
}
