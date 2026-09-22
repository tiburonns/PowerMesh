import Foundation
import SwiftUI
import WidgetKit

private struct WidgetBatterySnapshot: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let kind: String
    let level: Int?
    let state: String
    let updatedAt: Date
    let source: String
}

private struct BatteryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshots: [WidgetBatterySnapshot]
    let spanish: Bool
}

private enum WidgetSharedData {
    static let suite = "group.com.tiburonns.PowerMesh"
    static let snapshotsKey = "powermesh.cache.snapshots.v1"

    static func load() -> BatteryWidgetEntry {
        let defaults = UserDefaults(suiteName: suite)
        let data = defaults?.data(forKey: snapshotsKey)
        let snapshots = data.flatMap {
            try? JSONDecoder().decode([WidgetBatterySnapshot].self, from: $0)
        } ?? []

        let preference = defaults?.string(forKey: "appLanguage") ?? "system"
        let systemSpanish = Locale.preferredLanguages.first?
            .lowercased()
            .hasPrefix("es") == true
        let spanish = preference == "spanish"
            || (preference == "system" && systemSpanish)

        return BatteryWidgetEntry(
            date: .now,
            snapshots: snapshots.sorted { $0.updatedAt > $1.updatedAt },
            spanish: spanish
        )
    }
}

private struct BatteryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BatteryWidgetEntry {
        BatteryWidgetEntry(
            date: .now,
            snapshots: [
                WidgetBatterySnapshot(
                    id: "preview",
                    name: "iPhone",
                    kind: "iPhone",
                    level: 82,
                    state: "unplugged",
                    updatedAt: .now,
                    source: "Preview"
                )
            ],
            spanish: false
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (BatteryWidgetEntry) -> Void
    ) {
        completion(WidgetSharedData.load())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<BatteryWidgetEntry>) -> Void
    ) {
        let entry = WidgetSharedData.load()
        completion(
            Timeline(
                entries: [entry],
                policy: .after(Date(timeIntervalSinceNow: 15 * 60))
            )
        )
    }
}

private struct BatteryOverviewWidgetView: View {
    let entry: BatteryWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circular
            case .accessoryInline:
                inline
            case .accessoryRectangular:
                rectangular
            default:
                systemWidget
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var first: WidgetBatterySnapshot? {
        entry.snapshots.first
    }

    private var emptyText: String {
        entry.spanish ? "Abre PowerMesh" : "Open PowerMesh"
    }

    @ViewBuilder
    private var circular: some View {
        if let snapshot = first, let level = snapshot.level {
            Gauge(value: Double(level), in: 0...100) {
                Image(systemName: icon(for: snapshot.kind))
            } currentValueLabel: {
                Text("\(level)")
                    .font(.caption2)
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else {
            Image(systemName: "battery.0")
        }
    }

    @ViewBuilder
    private var inline: some View {
        if let snapshot = first {
            Text("\(snapshot.name) \(snapshot.level.map { "\($0)%" } ?? "—")")
        } else {
            Text(emptyText)
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if entry.snapshots.isEmpty {
            Label(emptyText, systemImage: "battery.0")
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(entry.snapshots.prefix(2)) { snapshot in
                    HStack {
                        Image(systemName: icon(for: snapshot.kind))
                        Text(snapshot.name)
                            .lineLimit(1)
                        Spacer()
                        Text(snapshot.level.map { "\($0)%" } ?? "—")
                            .monospacedDigit()
                    }
                }
            }
            .font(.caption)
        }
    }

    @ViewBuilder
    private var systemWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PowerMesh")
                .font(.headline)

            if entry.snapshots.isEmpty {
                Spacer()
                Label(emptyText, systemImage: "battery.0")
                    .font(.caption)
                Spacer()
            } else {
                ForEach(entry.snapshots.prefix(maxItems)) { snapshot in
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: snapshot.kind))
                            .frame(width: 18)
                        Text(snapshot.name)
                            .lineLimit(1)
                        Spacer()
                        Text(snapshot.level.map { "\($0)%" } ?? "—")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
    }

    private var maxItems: Int {
        #if os(watchOS)
        return 2
        #else
        switch family {
        case .systemLarge, .systemExtraLarge: return 8
        case .systemMedium: return 4
        default: return 2
        }
        #endif
    }

    private func icon(for kind: String) -> String {
        switch kind {
        case "iPhone": return "iphone"
        case "iPad": return "ipad"
        case "mac": return "laptopcomputer"
        case "watch": return "applewatch"
        default: return "headphones"
        }
    }
}

struct BatteryOverviewWidget: Widget {
    let kind = "PowerMeshBatteryOverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: BatteryWidgetProvider()
        ) { entry in
            BatteryOverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        #if os(watchOS)
        return [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        #elseif os(macOS)
        return [.systemSmall, .systemMedium, .systemLarge]
        #else
        return [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ]
        #endif
    }
}
