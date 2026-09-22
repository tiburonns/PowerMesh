import SwiftUI

#if os(watchOS)
struct WatchSettingsView: View {
    @EnvironmentObject private var store: BatteryDashboardStore
    @Environment(\.appLanguage) private var language
    @AppStorage(AppLanguage.storageKey) private var languagePreference =
        AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section(language.text(.languageSection)) {
                Picker(language.text(.language), selection: $languagePreference) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.optionTitle(in: language))
                            .tag(option.rawValue)
                    }
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
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(language.text(.settings))
    }
}
#endif
