import CloudKit

final class Attraction: CloudKitable, Hashable, Identifiable {
    init(record: CKRecord) {
        self.record = record
    }

    var record: CKRecord

    var area: String { record["area"] as? String ?? "" }
    var distance: Double { record["distance"] as? Double ?? 0.0 }
    var heading: Double { record["heading"] as? Double ?? 0.0 }
    var id: String { name }
    var latitude: Double { record["latitude"] as? Double ?? 0.0 }
    var longitude: Double { record["longitude"] as? Double ?? 0.0 }
    var name: String { record["name"] as? String ?? "" }
    var pitch: Double { record["pitch"] as? Double ?? 0.0 }

    static func == (lhs: Attraction, rhs: Attraction) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
