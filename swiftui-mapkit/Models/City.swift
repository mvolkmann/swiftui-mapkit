import CoreLocation

struct City: Codable, Hashable, Identifiable {
    let name: String
    var attractions: [Attraction] = []

    var id: String { name }
}
