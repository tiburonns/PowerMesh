import SwiftUI

#if !os(watchOS)
struct SettingsView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languagePreference = AppLanguage.system.rawValue
    @AppStorage(BatteryAlertSettings.enabledKey) private var lowBatteryAlerts = false
    @AppStorage(BatteryAlertSettings.thresholdKey) private var lowBatteryThreshold = BatteryAlertSettings.defaultThreshold
    @AppStorage(AccessoryBatterySettings.enabledKey) private var bluetoothAccessories = false
    @State private var draftName = ""
    @State private var notificationPermissionDenied = false

    private var remoteDevices: [BatterySnapshot] {
        store.snapshots.filter { $0.id != DeviceIdentity.id }
    }

    private func t(_ english: String, _ spanish: String) -> String {
        language.resolved == .spanish ? spanish : english
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(language.text(.languageSection)) {
                    Picker(language.text(.language), selection: $languagePreference) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.optionTitle(in: language)).tag(option.rawValue)
                        }
                    }
                    Text(language.text(.languageHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.thisDevice)) {
                    TextField(language.text(.name), text: $draftName)
                    Text(language.text(.deviceNameHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.accessoriesSection)) {
                    Toggle(
                        language.text(.bluetoothAccessories),
                        isOn: $bluetoothAccessories
                    )
                    Text(language.text(.bluetoothAccessoriesHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(language.text(.alertsSection)) {
                    Toggle(language.text(.lowBatteryAlerts), isOn: $lowBatteryAlerts)

                    Stepper(value: $lowBatteryThreshold, in: 5...50, step: 5) {
                        HStack {
                            Text(language.text(.lowBatteryThreshold))
                            Spacer()
                            Text("\(lowBatteryThreshold)%").monospacedDigit()
                        }
                    }
                    .disabled(!lowBatteryAlerts)

                    Text(language.text(.lowBatteryAlertsHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if notificationPermissionDenied {
                        Text(language.text(.notificationPermissionDenied))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(language.text(.syncSection)) {
                    HStack {
                        Text(language.text(.lastSync))
                        Spacer()
                        if let date = store.lastSuccessfulSync {
                            Text(date, style: .relative)
                        } else {
                            Text(language.text(.never))
                        }
                    }
                    Text(language.text(.backgroundSyncHelp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(t("Support", "Soporte")) {
                    NavigationLink {
                        PowerMeshFeedbackView()
                    } label: {
                        Label(
                            t("Questions, suggestions and feedback", "Dudas, sugerencias y feedback"),
                            systemImage: "bubble.left.and.bubble.right"
                        )
                    }

                    Link(
                        t("Open GitHub Issues", "Abrir Issues de GitHub"),
                        destination: URL(string: "https://github.com/tiburonns/PowerMesh/issues")!
                    )
                }

                if !remoteDevices.isEmpty {
                    Section(language.text(.knownDevices)) {
                        ForEach(remoteDevices) { snapshot in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(snapshot.name)
                                    Text(snapshot.updatedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(language.text(.forgetDevice), role: .destructive) {
                                    Task { await store.forgetDevice(id: snapshot.id) }
                                }
                            }
                        }
                        Text(language.text(.knownDevicesHelp))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(language.text(.settings))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.save)) {
                        Task {
                            await store.renameLocalDevice(to: draftName)
                            dismiss()
                        }
                    }
                }
            }
            .onAppear { draftName = store.localDeviceName }
            .onChange(of: bluetoothAccessories) { _, enabled in
                store.setAccessoryScanning(enabled: enabled)
            }
            .onChange(of: lowBatteryAlerts) { _, enabled in
                guard enabled else { return }
                Task {
                    let granted = await BatteryNotificationService.requestAuthorization()
                    await MainActor.run {
                        notificationPermissionDenied = !granted
                        if !granted { lowBatteryAlerts = false }
                    }
                }
            }
        }
    }
}

private struct PowerMeshFeedbackView: View {
    private enum Category: String, CaseIterable, Identifiable {
        case question, suggestion, bug, feedback
        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            let spanish = language.resolved == .spanish
            switch self {
            case .question: spanish ? "Duda" : "Question"
            case .suggestion: spanish ? "Sugerencia" : "Suggestion"
            case .bug: spanish ? "Error" : "Bug / Error"
            case .feedback: spanish ? "Feedback general" : "General feedback"
            }
        }

        var issuePrefix: String {
            switch self {
            case .question: "Question"
            case .suggestion: "Suggestion"
            case .bug: "Bug"
            case .feedback: "Feedback"
            }
        }
    }

    @Environment(\.appLanguage) private var language
    @Environment(\.openURL) private var openURL
    @State private var category = Category.question
    @State private var message = ""

    private func t(_ english: String, _ spanish: String) -> String {
        language.resolved == .spanish ? spanish : english
    }

    var body: some View {
        Form {
            Section(t("Type", "Tipo")) {
                Picker(t("Category", "Categoría"), selection: $category) {
                    ForEach(Category.allCases) { option in
                        Text(option.title(language: language)).tag(option)
                    }
                }
            }

            Section(t("Message", "Mensaje")) {
                TextEditor(text: $message)
                    .frame(minHeight: 160)

                Text(t(
                    "Do not include passwords, Apple account details, device identifiers, or other sensitive information.",
                    "No incluyas contraseñas, datos de tu cuenta Apple, identificadores de dispositivo ni otra información sensible."
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    submit()
                } label: {
                    Label(
                        t("Open in GitHub", "Abrir en GitHub"),
                        systemImage: "paperplane.fill"
                    )
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text(t(
                    "GitHub will open so you can review and publish the report yourself.",
                    "GitHub se abrirá para que revises y publiques el reporte tú mismo."
                ))
            }
        }
        .navigationTitle(t("Feedback", "Feedback"))
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func submit() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = "/tiburonns/PowerMesh/issues/new"
        components.queryItems = [
            URLQueryItem(name: "title", value: "[\(category.issuePrefix)] "),
            URLQueryItem(
                name: "body",
                value: """
                \(message)

                ---
                App: PowerMesh
                Version: \(appVersion)
                """
            )
        ]

        if let url = components.url {
            openURL(url)
        }
    }
}

#endif
