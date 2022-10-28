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

extension Attraction: Encodable {
    enum CodingKeys: String, CodingKey {
        case area
        case distance
        case heading
        case latitude
        case longitude
        case name
        case pitch
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(area, forKey: .area)
        try container.encode(name, forKey: .name)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(distance, forKey: .distance)
        try container.encode(heading, forKey: .heading)
        try container.encode(pitch, forKey: .pitch)
    }
}
