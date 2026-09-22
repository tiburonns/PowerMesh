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
        case .system: return .autoupdatingCurrent
        case .english: return Locale(identifier: "en")
        case .spanish: return Locale(identifier: "es")
        }
    }

    var resolved: ResolvedAppLanguage {
        switch self {
        case .english: return .english
        case .spanish: return .spanish
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
        case .system: return currentLanguage.text(.systemLanguage)
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

enum ResolvedAppLanguage: Equatable {
    case english
    case spanish
}

enum AppText: String, Hashable {
    case batteriesTitle, refresh, settings, noDevicesTitle, noDevicesMessage
    case syncError, iCloudUnavailable, thisDevice, name, deviceNameHelp
    case knownDevices, knownDevicesHelp, forgetDevice
    case languageSection, language, languageHelp, systemLanguage, cancel, save
    case charging, battery, percent, noInternalBattery, staleData, updated, accessory
    case chargeOnBattery, chargeFull, chargeExternalPower, chargeUnknown
    case statusLive, statusRecent, statusStale, statusOffline, status
    case batteryHistory, historyEmpty, historySevenDays, samples, lastUpdate, source
    case alertsSection, lowBatteryAlerts, lowBatteryAlertsHelp, lowBatteryThreshold
    case notificationPermissionDenied, syncSection, lastSync, never
    case backgroundSyncHelp, lowBatteryTitle
    case accessoriesSection, bluetoothAccessories, bluetoothAccessoriesHelp
    case trend, insufficientData, hourShort
    case lowBatteryMessageFormat, bluetoothAccessoryDefaultName

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
        .iCloudUnavailable: "iCloud is not available for PowerMesh on this device.",
        .thisDevice: "This device",
        .name: "Name",
        .deviceNameHelp: "The name is stored locally and published only to your private CloudKit database.",
        .knownDevices: "Known devices",
        .knownDevicesHelp: "Remove obsolete snapshots that should no longer appear in your private PowerMesh dashboard.",
        .forgetDevice: "Forget",
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
        .chargeUnknown: "Unknown status",
        .statusLive: "Live",
        .statusRecent: "Recent",
        .statusStale: "Stale",
        .statusOffline: "Offline",
        .status: "Status",
        .batteryHistory: "Battery history",
        .historyEmpty: "History will appear as PowerMesh collects battery snapshots.",
        .historySevenDays: "Up to 7 days",
        .samples: "samples",
        .lastUpdate: "Last update",
        .source: "Source",
        .alertsSection: "Alerts",
        .lowBatteryAlerts: "Low-battery alerts",
        .lowBatteryAlertsHelp: "Notify this device when a recently seen PowerMesh device falls below your threshold.",
        .lowBatteryThreshold: "Alert threshold",
        .notificationPermissionDenied: "Notifications are disabled for PowerMesh in system settings.",
        .syncSection: "Sync",
        .lastSync: "Last successful sync",
        .never: "Never",
        .backgroundSyncHelp: "Background refresh and CloudKit pushes are opportunistic. PowerMesh always shows when each reading was last updated.",
        .lowBatteryTitle: "Low battery",
        .accessoriesSection: "Accessories",
        .bluetoothAccessories: "Compatible Bluetooth batteries",
        .bluetoothAccessoriesHelp: "Scans only for nearby accessories that publicly expose the standard Bluetooth Battery Service. Compatibility is not guaranteed for AirPods, Apple Pencil, or proprietary accessories.",
        .trend: "Trend",
        .insufficientData: "Collecting data",
        .hourShort: "h",
        .lowBatteryMessageFormat: "%@ has %d%% battery remaining.",
        .bluetoothAccessoryDefaultName: "Bluetooth Accessory"
    ]

    private static let spanish: [AppText: String] = [
        .batteriesTitle: "Baterías",
        .refresh: "Actualizar",
        .settings: "Configuración",
        .noDevicesTitle: "Sin dispositivos todavía",
        .noDevicesMessage: "Instala y abre PowerMesh en tus dispositivos Apple con la misma cuenta de iCloud.",
        .syncError: "No se pudo sincronizar con iCloud. Verifica que CloudKit esté habilitado para este target y que el dispositivo tenga una cuenta de iCloud activa.",
        .iCloudUnavailable: "iCloud no está disponible para PowerMesh en este dispositivo.",
        .thisDevice: "Este dispositivo",
        .name: "Nombre",
        .deviceNameHelp: "El nombre se guarda localmente y se publica únicamente en tu base privada de CloudKit.",
        .knownDevices: "Dispositivos conocidos",
        .knownDevicesHelp: "Elimina snapshots obsoletos que ya no deban aparecer en tu dashboard privado de PowerMesh.",
        .forgetDevice: "Olvidar",
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
        .chargeUnknown: "Estado desconocido",
        .statusLive: "En vivo",
        .statusRecent: "Reciente",
        .statusStale: "Desactualizado",
        .statusOffline: "Sin conexión",
        .status: "Estado",
        .batteryHistory: "Historial de batería",
        .historyEmpty: "El historial aparecerá conforme PowerMesh recopile lecturas de batería.",
        .historySevenDays: "Hasta 7 días",
        .samples: "muestras",
        .lastUpdate: "Última actualización",
        .source: "Fuente",
        .alertsSection: "Alertas",
        .lowBatteryAlerts: "Alertas de batería baja",
        .lowBatteryAlertsHelp: "Notifica en este dispositivo cuando un dispositivo visto recientemente por PowerMesh baje del umbral elegido.",
        .lowBatteryThreshold: "Umbral de alerta",
        .notificationPermissionDenied: "Las notificaciones están desactivadas para PowerMesh en los ajustes del sistema.",
        .syncSection: "Sincronización",
        .lastSync: "Última sincronización correcta",
        .never: "Nunca",
        .backgroundSyncHelp: "La actualización en segundo plano y los avisos de CloudKit son oportunistas. PowerMesh siempre muestra cuándo se actualizó por última vez cada lectura.",
        .lowBatteryTitle: "Batería baja",
        .accessoriesSection: "Accesorios",
        .bluetoothAccessories: "Baterías Bluetooth compatibles",
        .bluetoothAccessoriesHelp: "Busca únicamente accesorios cercanos que exponen públicamente el servicio estándar de batería de Bluetooth. No se garantiza compatibilidad con AirPods, Apple Pencil ni accesorios propietarios.",
        .trend: "Tendencia",
        .insufficientData: "Recopilando datos",
        .hourShort: "h",
        .lowBatteryMessageFormat: "%@ tiene %d%% de batería.",
        .bluetoothAccessoryDefaultName: "Accesorio Bluetooth"
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
