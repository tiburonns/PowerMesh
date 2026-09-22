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

enum BatteryAlertPolicy {
    static func shouldAlert(
        snapshot: BatterySnapshot,
        threshold: Int,
        previousAlertLevel: Int?,
        now: Date = .now
    ) -> Bool {
        guard let level = snapshot.level,
              level <= threshold,
              snapshot.state == .unplugged else {
            return false
        }

        switch snapshot.availability(at: now) {
        case .live, .recent:
            break
        case .stale, .offline:
            return false
        }

        guard let previousAlertLevel else { return true }
        return level <= previousAlertLevel - 5
    }

    static func shouldReset(
        snapshot: BatterySnapshot,
        threshold: Int
    ) -> Bool {
        guard let level = snapshot.level else { return false }
        return level > threshold + 5
            || snapshot.state == .charging
            || snapshot.state == .full
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
            let key = lastAlertPrefix + snapshot.id
            let previousLevel = UserDefaults.standard.object(forKey: key) as? Int

            if BatteryAlertPolicy.shouldReset(
                snapshot: snapshot,
                threshold: threshold
            ) {
                UserDefaults.standard.removeObject(forKey: key)
            }

            guard BatteryAlertPolicy.shouldAlert(
                snapshot: snapshot,
                threshold: threshold,
                previousAlertLevel: previousLevel,
                now: now
            ),
            let level = snapshot.level else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = language.text(.lowBatteryTitle)
            content.body = String(
                format: language.text(.lowBatteryMessageFormat),
                locale: language.locale,
                snapshot.name,
                level
            )
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
}
