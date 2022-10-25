import CoreLocation

struct Attraction: Codable, Hashable, Identifiable {
    let name: String
    let latitude: Double // in degrees
    let longitude: Double // in degrees
    let radius: Double // in meters
    let heading: Double // in degrees
    let pitch: Double // in degrees

    var id: String { name }

    static func == (lhs: Attraction, rhs: Attraction) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
