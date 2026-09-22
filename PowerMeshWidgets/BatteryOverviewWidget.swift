import Foundation
import SwiftUI
import WidgetKit

private enum WidgetFreshness {
    case live
    case recent
    case stale
    case offline
}

private struct WidgetBatterySnapshot: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let kind: String
    let level: Int?
    let state: String
    let updatedAt: Date
    let source: String

    func freshness(at now: Date) -> WidgetFreshness {
        let age = max(0, now.timeIntervalSince(updatedAt))
        switch age {
        case ..<(5 * 60): return .live
        case ..<(30 * 60): return .recent
        case ..<(2 * 60 * 60): return .stale
        default: return .offline
        }
    }
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
            #if os(watchOS)
            case .accessoryCorner:
                corner
            #endif
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
        localized("widget.openPowerMesh")
    }

    private func localized(_ key: String) -> String {
        let language = entry.spanish ? "es" : "en"
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    private func staleLabel(for snapshot: WidgetBatterySnapshot) -> String? {
        switch snapshot.freshness(at: entry.date) {
        case .live, .recent:
            return nil
        case .stale:
            return localized("widget.stale")
        case .offline:
            return localized("widget.offline")
        }
    }

    private func statusIcon(for snapshot: WidgetBatterySnapshot) -> String? {
        switch snapshot.freshness(at: entry.date) {
        case .live, .recent:
            return nil
        case .stale:
            return "clock.badge.exclamationmark"
        case .offline:
            return "exclamationmark.circle"
        }
    }

    @ViewBuilder
    private var circular: some View {
        if let snapshot = first, let level = snapshot.level {
            Gauge(value: Double(level), in: 0...100) {
                Image(systemName: statusIcon(for: snapshot) ?? icon(for: snapshot.kind))
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
            let suffix = staleLabel(for: snapshot).map { " · \($0)" } ?? ""
            Text("\(snapshot.name) \(snapshot.level.map { "\($0)%" } ?? "—")\(suffix)")
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
                        Image(systemName: statusIcon(for: snapshot) ?? icon(for: snapshot.kind))
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

    #if os(watchOS)
    @ViewBuilder
    private var corner: some View {
        if let snapshot = first {
            Text(snapshot.level.map { "\($0)%" } ?? "—")
                .widgetLabel(
                    staleLabel(for: snapshot)
                    ?? snapshot.name
                )
        } else {
            Image(systemName: "battery.0")
                .widgetLabel(emptyText)
        }
    }
    #endif

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
                        Image(systemName: statusIcon(for: snapshot) ?? icon(for: snapshot.kind))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(snapshot.name)
                                .lineLimit(1)
                            if let stale = staleLabel(for: snapshot) {
                                Text(stale)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
        return [
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ]
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
