import Foundation

enum PowerMeshTestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

@main
struct PowerMeshCoreIntegration {
    static func main() throws {
        try testStalenessBoundary()
        try testReconciliationPrefersNewestRemoteDuplicate()
        try testLocalSnapshotOverridesCloudCopy()
        try testLanguageFallbacks()
        try testSyncIssueLocalization()
        print("PASS: PowerMesh staleness, reconciliation, and localization")
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw PowerMeshTestFailure.failed(message)
        }
    }

    private static func snapshot(
        id: String,
        name: String,
        updatedAt: Date,
        level: Int
    ) -> BatterySnapshot {
        BatterySnapshot(
            id: id,
            name: name,
            kind: .iPhone,
            level: level,
            state: .unplugged,
            updatedAt: updatedAt,
            source: "test"
        )
    }

    private static func testStalenessBoundary() throws {
        let now = Date(timeIntervalSince1970: 10_000)
        let fresh = snapshot(
            id: "fresh",
            name: "Fresh",
            updatedAt: now.addingTimeInterval(-1_799),
            level: 80
        )
        let stale = snapshot(
            id: "stale",
            name: "Stale",
            updatedAt: now.addingTimeInterval(-1_801),
            level: 70
        )

        try require(!fresh.isStale(at: now), "Fresh snapshot was marked stale")
        try require(stale.isStale(at: now), "Stale snapshot was marked fresh")
    }

    private static func testReconciliationPrefersNewestRemoteDuplicate() throws {
        let older = snapshot(
            id: "same",
            name: "Old",
            updatedAt: Date(timeIntervalSince1970: 100),
            level: 20
        )
        let newer = snapshot(
            id: "same",
            name: "New",
            updatedAt: Date(timeIntervalSince1970: 200),
            level: 90
        )

        let merged = BatterySnapshotReconciler.merge(
            remote: [older, newer],
            local: nil
        )

        try require(merged.count == 1, "Duplicate device IDs were not deduplicated")
        try require(merged[0].name == "New", "Older CloudKit duplicate won reconciliation")
        try require(merged[0].level == 90, "Newest CloudKit battery level was lost")
    }

    private static func testLocalSnapshotOverridesCloudCopy() throws {
        let cloud = snapshot(
            id: "local",
            name: "Cloud copy",
            updatedAt: Date(timeIntervalSince1970: 500),
            level: 5
        )
        let local = snapshot(
            id: "local",
            name: "Current device",
            updatedAt: Date(timeIntervalSince1970: 400),
            level: 95
        )
        let other = snapshot(
            id: "other",
            name: "Other device",
            updatedAt: Date(timeIntervalSince1970: 450),
            level: 50
        )

        let merged = BatterySnapshotReconciler.merge(
            remote: [cloud, other],
            local: local
        )

        try require(merged.count == 2, "Reconciliation changed device count unexpectedly")
        let localResult = merged.first { $0.id == "local" }
        try require(localResult?.name == "Current device", "Cloud copy overrode the authoritative local snapshot")
        try require(localResult?.level == 95, "Local battery level was not preserved")
    }

    private static func testSyncIssueLocalization() throws {
        try require(
            DashboardSyncIssue.iCloudUnavailable.message(in: .english)
                == "iCloud is not available for PowerMesh on this device.",
            "English iCloud availability message failed"
        )
        try require(
            DashboardSyncIssue.iCloudUnavailable.message(in: .spanish)
                == "iCloud no está disponible para PowerMesh en este dispositivo.",
            "Spanish iCloud availability message failed"
        )
    }

    private static func testLanguageFallbacks() throws {
        try require(
            AppLanguage.english.text(.batteriesTitle) == "Batteries",
            "English localization failed"
        )
        try require(
            AppLanguage.spanish.text(.batteriesTitle) == "Baterías",
            "Spanish localization failed"
        )
        try require(
            AppLanguage.spanish.optionTitle(in: .english) == "Español",
            "Language picker title changed unexpectedly"
        )
    }
}
