import CoreLocation

struct Attraction: Hashable, Identifiable {
    let city: City
    let name: String
    let address: String?
    let coordinate: CLLocationCoordinate2D
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

    var lookupAddress: String {
        address ?? "\(name), \(city.name)"
    }
}
