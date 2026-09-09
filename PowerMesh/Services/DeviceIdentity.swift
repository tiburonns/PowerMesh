import Foundation

#if os(iOS)
import UIKit
#endif

struct DeviceIdentity {
    private static let idKey = "powermesh.device.id"
    private static let nameKey = "powermesh.device.name"

    static var id: String {
        if let existing = UserDefaults.standard.string(forKey: idKey), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: idKey)
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
}
