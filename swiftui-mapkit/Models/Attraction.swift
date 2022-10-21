import CoreLocation

struct Attraction: Codable, Hashable, Identifiable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let distance: Double
    let heading: Double
    let pitch: Double

    var id: String { name }

    static func == (lhs: Attraction, rhs: Attraction) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
