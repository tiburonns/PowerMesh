import Foundation
import UserNotifications

enum BatteryAlertSettings {
    static let enabledKey = "powermesh.alerts.lowBattery.enabled"
    static let thresholdKey = "powermesh.alerts.lowBattery.threshold"
    static let defaultThreshold = 20

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var threshold: Int {
        let stored = UserDefaults.standard.integer(forKey: thresholdKey)
        return stored == 0 ? defaultThreshold : min(50, max(5, stored))
    }
}

enum BatteryNotificationService {
    private static let lastAlertPrefix = "powermesh.alerts.last."

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func evaluate(
        snapshots: [BatterySnapshot],
        language: AppLanguage,
        now: Date = .now
    ) async {
        guard BatteryAlertSettings.isEnabled else { return }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        let threshold = BatteryAlertSettings.threshold
        for snapshot in snapshots {
            guard let level = snapshot.level,
                  level <= threshold,
                  snapshot.state == .unplugged,
                  snapshot.availability(at: now) != .offline else {
                resetAlertIfRecovered(snapshot, threshold: threshold)
                continue
            }

            let key = lastAlertPrefix + snapshot.id
            let previousLevel = UserDefaults.standard.object(forKey: key) as? Int
            guard previousLevel == nil || level <= previousLevel! - 5 else { continue }

            let content = UNMutableNotificationContent()
            content.title = language.text(.lowBatteryTitle)
            content.body = language.resolved == .spanish
                ? "\(snapshot.name) tiene \(level)% de batería."
                : "\(snapshot.name) has \(level)% battery remaining."
            content.sound = .default
            content.threadIdentifier = "powermesh-low-battery"

            let request = UNNotificationRequest(
                identifier: "powermesh-low-\(snapshot.id)-\(level)",
                content: content,
                trigger: nil
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
                UserDefaults.standard.set(level, forKey: key)
            } catch {
                // Notification delivery failure must never break battery sync.
            }
        }
    }

    private static func resetAlertIfRecovered(
        _ snapshot: BatterySnapshot,
        threshold: Int
    ) {
        guard let level = snapshot.level else { return }
        if level > threshold + 5 || snapshot.state == .charging || snapshot.state == .full {
            UserDefaults.standard.removeObject(forKey: lastAlertPrefix + snapshot.id)
        }
    }
}
