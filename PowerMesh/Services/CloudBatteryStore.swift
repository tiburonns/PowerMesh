import CloudKit
import Foundation

actor CloudBatteryStore {
    static let recordType = "BatterySnapshot"

    private let database: CKDatabase

    init(container: CKContainer = .default()) {
        database = container.privateCloudDatabase
    }

    func upsert(_ snapshot: BatterySnapshot) async throws {
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

    func fetchAll() async throws -> [BatterySnapshot] {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        var snapshots: [BatterySnapshot] = []
        var cursor: CKQueryOperation.Cursor?

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
                guard case let .success(record) = result,
                      let snapshot = decode(record) else { continue }
                snapshots.append(snapshot)
            }

            cursor = page.queryCursor
        } while cursor != nil

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

        return BatterySnapshot(
            id: deviceID,
            name: deviceName,
            kind: kind,
            level: level,
            state: state,
            updatedAt: updatedAt,
            source: source
        )
    }
}
