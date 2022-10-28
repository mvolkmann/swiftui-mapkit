import CloudKit
import CoreLocation

final class Area: CloudKitable, Hashable, Identifiable {
    init(record: CKRecord) {
        self.record = record
    }

    var id: String { name }

    var record: CKRecord

    var name: String { record["name"] as? String ?? "" }
    var attractions: [Attraction] = []

    func addAttraction(_ attraction: Attraction) {
        attractions.append(attraction)
    }

    func sortAttractions() {
        attractions.sort(by: { $0.name < $1.name })
    }

    // This is required by the Equatable protocol.
    static func == (lhs: Area, rhs: Area) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Area: Encodable {
    enum CodingKeys: String, CodingKey {
        case name
        case attractions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(attractions, forKey: .attractions)
    }
}
