import SwiftUI

#if os(macOS)
struct CompactMenuView: View {
    @EnvironmentObject private var store: BatteryDashboardStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.snapshots.prefix(8)) { snapshot in
                HStack {
                    Image(systemName: snapshot.kind.systemImage)
                        .frame(width: 22)
                    Text(snapshot.name)
                        .lineLimit(1)
                    Spacer()
                    if let level = snapshot.level {
                        Text("\(level)%")
                            .monospacedDigit()
                    } else {
                        Text("—")
                    }
                }
            }

            Divider()

            Button("Actualizar") {
                Task { await store.refreshNow() }
            }
        }
        .padding(8)
        .frame(minWidth: 260)
        .task { store.start() }
    }
}
#endif
