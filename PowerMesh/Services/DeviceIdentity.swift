import Foundation
import Security

#if os(iOS)
import UIKit
#endif

struct DeviceIdentity {
    private static let legacyIDKey = "powermesh.device.id"
    private static let nameKey = "powermesh.device.name"
    private static let keychainService = "com.tiburonns.PowerMesh.device"
    private static let keychainAccount = "stable-device-id"

    static var id: String {
        if let existing = loadStableID(), !existing.isEmpty {
            return existing
        }

        if let legacy = UserDefaults.standard.string(forKey: legacyIDKey),
           !legacy.isEmpty {
            if saveStableID(legacy) {
                UserDefaults.standard.removeObject(forKey: legacyIDKey)
            }
            return legacy
        }

        let newID = UUID().uuidString
        if !saveStableID(newID) {
            // Keep a durable fallback so a transient Keychain failure does not
            // generate a different logical device on every launch.
            UserDefaults.standard.set(newID, forKey: legacyIDKey)
        }
        return newID
    }

    static var name: String {
        get {
            if let custom = UserDefaults.standard.string(forKey: nameKey), !custom.isEmpty {
                return custom
            }
            return defaultName
        }
        set {
            let clean = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                UserDefaults.standard.removeObject(forKey: nameKey)
            } else {
                UserDefaults.standard.set(clean, forKey: nameKey)
            }
        }
    }

    static var defaultName: String {
        #if os(macOS)
        return Host.current().localizedName ?? "Mac"
        #elseif os(watchOS)
        return "Apple Watch"
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #else
        return "Dispositivo Apple"
        #endif
    }

    private static func loadStableID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    @discardableResult
    private static func saveStableID(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        let update: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            lookup as CFDictionary,
            update as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var create = lookup
        create[kSecValueData as String] = data
        create[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(create as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return true
        }

        // A concurrent first access can win the add race. In that case,
        // accept the item only if it contains the same stable ID.
        if addStatus == errSecDuplicateItem {
            return loadStableID() == value
        }

        return false
    }
}
