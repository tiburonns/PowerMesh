import SwiftUI

struct DeviceDetailView: View {
    let snapshot: BatterySnapshot

    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language

    private var currentSnapshot: BatterySnapshot {
        store.snapshots.first(where: { $0.id == snapshot.id }) ?? snapshot
    }

    private var history: [BatteryHistoryPoint] {
        store.history(for: snapshot.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BatteryCard(snapshot: currentSnapshot)

                VStack(alignment: .leading, spacing: 10) {
                    Text(language.text(.batteryHistory))
                        .font(.headline)

                    if history.isEmpty {
                        Text(language.text(.historyEmpty))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        BatteryHistoryChart(points: history)
                            .frame(height: 130)

                        HStack {
                            Text(language.text(.historySevenDays))
                            Spacer()
                            Text("\(history.count) \(language.text(.samples))")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    detailRow(language.text(.status), currentSnapshot.availability.displayName(in: language))
                    detailRow(
                        language.text(.lastUpdate),
                        currentSnapshot.updatedAt.formatted(date: .abbreviated, time: .standard)
                    )
                    detailRow(language.text(.source), currentSnapshot.source)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding()
        }
        .navigationTitle(currentSnapshot.name)
    }

    @ViewBuilder
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}

private struct BatteryHistoryChart: View {
    let points: [BatteryHistoryPoint]

    private var visiblePoints: [BatteryHistoryPoint] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let recent = points.filter { $0.date >= cutoff }
        return recent.isEmpty ? Array(points.suffix(48)) : recent
    }

    var body: some View {
        GeometryReader { proxy in
            let values = visiblePoints
            Path { path in
                guard let first = values.first else { return }
                let width = proxy.size.width
                let height = proxy.size.height
                let count = max(values.count - 1, 1)

                func point(index: Int, level: Int) -> CGPoint {
                    CGPoint(
                        x: width * CGFloat(index) / CGFloat(count),
                        y: height * (1 - CGFloat(level) / 100)
                    )
                }

                path.move(to: point(index: 0, level: first.level))
                for (index, value) in values.dropFirst().enumerated() {
                    path.addLine(to: point(index: index + 1, level: value.level))
                }
            }
            .stroke(
                .primary,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language.text(.batteryHistory))
    }
}
