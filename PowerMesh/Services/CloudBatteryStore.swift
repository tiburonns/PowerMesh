import CloudKit
import Foundation

enum CloudBatteryStoreError: LocalizedError, Equatable {
    case iCloudUnavailable
    case invalidSnapshot

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud is unavailable."
        case .invalidSnapshot:
            return "The battery snapshot contains invalid sync data."
        }
    }
}

protocol BatteryCloudStore: Sendable {
    func upsert(_ snapshot: BatterySnapshot) async throws
    func delete(deviceID: String) async throws
    func fetchAll() async throws -> [BatterySnapshot]
}

#if POWERMESH_LOCAL_ONLY
actor CloudBatteryStore: BatteryCloudStore {
    static let recordType = "BatterySnapshot"
    static let containerIdentifier = "iCloud.com.tiburonns.PowerMesh"

    func upsert(_ snapshot: BatterySnapshot) async throws {
        // Intentionally disabled in the Local test configuration.
        // The local battery snapshot is still kept in BatteryDashboardStore.
    }

    func delete(deviceID: String) async throws {
        // No remote data exists in the Local test configuration.
    }

    func fetchAll() async throws -> [BatterySnapshot] {
        []
    }
}
#else
actor CloudBatteryStore: BatteryCloudStore {
    static let recordType = "BatterySnapshot"
    static let containerIdentifier = "iCloud.com.tiburonns.PowerMesh"

    private var database: CKDatabase?

    private func privateDatabase() throws -> CKDatabase {
        if let database = database {
            return database
        }

        guard FileManager.default.ubiquityIdentityToken != nil else {
            throw CloudBatteryStoreError.iCloudUnavailable
        }

        let createdDatabase = CKContainer(
            identifier: Self.containerIdentifier
        ).privateCloudDatabase
        database = createdDatabase
        return createdDatabase
    }

    func upsert(_ snapshot: BatterySnapshot) async throws {
        guard snapshot.isValidForSync else {
            throw CloudBatteryStoreError.invalidSnapshot
        }

        let database = try privateDatabase()
        let recordID = CKRecord.ID(recordName: "device-\(snapshot.id)")
        let record: CKRecord

        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        }

        record["deviceID"] = snapshot.id as CKRecordValue
        record["deviceName"] = snapshot.name as CKRecordValue
        record["kind"] = snapshot.kind.rawValue as CKRecordValue
        record["chargeState"] = snapshot.state.rawValue as CKRecordValue
        record["updatedAt"] = snapshot.updatedAt as CKRecordValue
        record["source"] = snapshot.source as CKRecordValue

        if let level = snapshot.level {
            record["level"] = NSNumber(value: level)
        } else {
            record["level"] = nil
        }

        _ = try await database.save(record)
    }

    func delete(deviceID: String) async throws {
        let database = try privateDatabase()
        let recordID = CKRecord.ID(recordName: "device-\(deviceID)")
        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return
        }
    }

    func fetchAll() async throws -> [BatterySnapshot] {
        let database = try privateDatabase()
        let query = CKQuery(
            recordType: Self.recordType,
            predicate: NSPredicate(value: true)
        )

        var snapshots: [BatterySnapshot] = []
        var cursor: CKQueryOperation.Cursor?
        var firstRecordError: Error?

        repeat {
            let page: (
                matchResults: [(CKRecord.ID, Result<CKRecord, Error>)],
                queryCursor: CKQueryOperation.Cursor?
            )

            if let cursor = cursor {
                page = try await database.records(
                    continuingMatchFrom: cursor,
                    resultsLimit: 100
                )
            } else {
                page = try await database.records(
                    matching: query,
                    resultsLimit: 100
                )
            }

            for (_, result) in page.matchResults {
                switch result {
                case .success(let record):
                    if let snapshot = decode(record) {
                        snapshots.append(snapshot)
                    }
                case .failure(let error):
                    if firstRecordError == nil {
                        firstRecordError = error
                    }
                }
            }

            cursor = page.queryCursor
        } while cursor != nil

        if let firstRecordError {
            throw firstRecordError
        }

        return snapshots.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func decode(_ record: CKRecord) -> BatterySnapshot? {
        guard let deviceID = record["deviceID"] as? String,
              let deviceName = record["deviceName"] as? String,
              let kindRaw = record["kind"] as? String,
              let kind = DeviceKind(rawValue: kindRaw),
              let stateRaw = record["chargeState"] as? String,
              let state = ChargeState(rawValue: stateRaw),
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }

        let level = (record["level"] as? NSNumber)?.intValue
        let source = record["source"] as? String ?? "Unknown"

        let snapshot = BatterySnapshot(
            id: deviceID,
            name: deviceName,
            kind: kind,
            level: level,
            state: state,
            updatedAt: updatedAt,
            source: source
        )

        return snapshot.isValidForSync ? snapshot : nil
    }
}

#endif
