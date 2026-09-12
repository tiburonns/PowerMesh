import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    static let storageKey = "appLanguage"

    case system
    case english
    case spanish

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .spanish:
            return Locale(identifier: "es")
        }
    }

    var resolved: ResolvedAppLanguage {
        switch self {
        case .english:
            return .english
        case .spanish:
            return .spanish
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return preferred.hasPrefix("es") ? .spanish : .english
        }
    }

    func text(_ key: AppText) -> String {
        key.value(for: resolved)
    }

    func optionTitle(in currentLanguage: AppLanguage) -> String {
        switch self {
        case .system:
            return currentLanguage.text(.systemLanguage)
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
}

enum ResolvedAppLanguage: Equatable {
    case english
    case spanish
}

enum AppText: String, Hashable {
    case batteriesTitle
    case refresh
    case settings
    case noDevicesTitle
    case noDevicesMessage
    case syncError
    case thisDevice
    case name
    case deviceNameHelp
    case languageSection
    case language
    case languageHelp
    case systemLanguage
    case cancel
    case save
    case charging
    case battery
    case percent
    case noInternalBattery
    case staleData
    case updated
    case accessory
    case chargeOnBattery
    case chargeFull
    case chargeExternalPower
    case chargeUnknown

    fileprivate func value(for language: ResolvedAppLanguage) -> String {
        let table = language == .spanish ? Self.spanish : Self.english
        return table[self] ?? Self.english[self] ?? rawValue
    }

    private static let english: [AppText: String] = [
        .batteriesTitle: "Batteries",
        .refresh: "Refresh",
        .settings: "Settings",
        .noDevicesTitle: "No devices yet",
        .noDevicesMessage: "Install and open PowerMesh on your Apple devices using the same iCloud account.",
        .syncError: "Could not sync with iCloud. Make sure CloudKit is enabled for this target and the device is signed in to iCloud.",
        .thisDevice: "This device",
        .name: "Name",
        .deviceNameHelp: "The name is stored locally and published only to your private CloudKit database.",
        .languageSection: "Language",
        .language: "App language",
        .languageHelp: "Choose System to follow the device language. PowerMesh currently supports English and Spanish; unsupported system languages fall back to English.",
        .systemLanguage: "System",
        .cancel: "Cancel",
        .save: "Save",
        .charging: "Charging",
        .battery: "Battery",
        .percent: "percent",
        .noInternalBattery: "No internal battery",
        .staleData: "Stale data",
        .updated: "Updated",
        .accessory: "Accessory",
        .chargeOnBattery: "On battery",
        .chargeFull: "Fully charged",
        .chargeExternalPower: "External power",
        .chargeUnknown: "Unknown status"
    ]

    private static let spanish: [AppText: String] = [
        .batteriesTitle: "Baterías",
        .refresh: "Actualizar",
        .settings: "Configuración",
        .noDevicesTitle: "Sin dispositivos todavía",
        .noDevicesMessage: "Instala y abre PowerMesh en tus dispositivos Apple con la misma cuenta de iCloud.",
        .syncError: "No se pudo sincronizar con iCloud. Verifica que CloudKit esté habilitado para este target y que el dispositivo tenga una cuenta de iCloud activa.",
        .thisDevice: "Este dispositivo",
        .name: "Nombre",
        .deviceNameHelp: "El nombre se guarda localmente y se publica únicamente en tu base privada de CloudKit.",
        .languageSection: "Idioma",
        .language: "Idioma de la app",
        .languageHelp: "Elige Sistema para seguir el idioma del dispositivo. PowerMesh admite actualmente inglés y español; otros idiomas del sistema usan inglés como alternativa.",
        .systemLanguage: "Sistema",
        .cancel: "Cancelar",
        .save: "Guardar",
        .charging: "Cargando",
        .battery: "Batería",
        .percent: "por ciento",
        .noInternalBattery: "Sin batería interna",
        .staleData: "Dato antiguo",
        .updated: "Actualizado",
        .accessory: "Accesorio",
        .chargeOnBattery: "Con batería",
        .chargeFull: "Carga completa",
        .chargeExternalPower: "Alimentación externa",
        .chargeUnknown: "Estado desconocido"
    ]
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .system
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}
