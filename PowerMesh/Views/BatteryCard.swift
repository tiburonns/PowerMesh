import SwiftUI

struct BatteryCard: View {
    let snapshot: BatterySnapshot

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
                    Text(snapshot.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)

                if snapshot.state == .charging {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Cargando")
                }
            }

            if let level = snapshot.level {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(level)%")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                    Spacer()
                    Text(snapshot.state.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(level), total: 100)
                    .accessibilityLabel("Batería")
                    .accessibilityValue("\(level) por ciento")
            } else {
                Text("Sin batería interna")
                    .font(.headline)
                Text(snapshot.state.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundStyle(snapshot.isStale ? .secondary : .primary)
                Text(snapshot.isStale ? "Dato antiguo" : "Actualizado")
                Text(snapshot.updatedAt, style: .relative)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
