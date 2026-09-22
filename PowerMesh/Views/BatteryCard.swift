import SwiftUI

struct BatteryCard: View {
    let snapshot: BatterySnapshot

    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: snapshot.kind.systemImage)
                    .font(.title2)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(snapshot.kind.displayName(in: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)

                if snapshot.state == .charging {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(language.text(.charging))
                }
            }

            if let level = snapshot.level {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(level)%")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                    Spacer()
                    Text(snapshot.state.displayName(in: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(level), total: 100)
                    .accessibilityLabel(language.text(.battery))
                    .accessibilityValue("\(level) \(language.text(.percent))")
            } else {
                Text(language.text(.noInternalBattery))
                    .font(.headline)
                Text(snapshot.state.displayName(in: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .frame(width: 7, height: 7)
                Text(snapshot.availability.displayName(in: language))
                Text("•")
                Text(snapshot.updatedAt, style: .relative)
            }
            .font(.caption2)
            .foregroundStyle(snapshot.availability == .live ? .primary : .secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
