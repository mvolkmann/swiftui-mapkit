import CoreLocation

struct City: Hashable, Identifiable {
    let name: String
    var attractions: [Attraction] = []

    var id: String { name }

    mutating func addAttraction(
        name: String,
        address: String? = nil,
        coordinate: CLLocationCoordinate2D,
        distance: Double,
        heading: Double,
        pitch: Double
    ) {
        attractions.append(Attraction(
            city: self, name: name, address: address, coordinate: coordinate,
            distance: distance, heading: heading, pitch: pitch
        ))
    }
}

private func setup() -> [City] {
    var london = City(name: "London")
    london.addAttraction(
        name: "Buckingham Palace",
        address: "Buckingham Palace, London SW1A 1AA",
        coordinate: CLLocationCoordinate2D(
            latitude: 51.5014,
            longitude: -0.1415
        ),
        distance: 100.0,
        heading: 237.0,
        pitch: 72.0
    )

    london.addAttraction(
        name: "Kensington Palace",
        address: "Kensington Gardens, London W8 4PX",
        coordinate: CLLocationCoordinate2D(
            latitude: 51.50528021513012,
            longitude: -0.18738961435642476
        ),
        distance: 100.0,
        heading: 256.0,
        pitch: 72.0
    )
    london.addAttraction(
        name: "Tower Bridge",
        address: "Tower Bridge Rd, London SE1 2UP",
        coordinate: CLLocationCoordinate2D(
            latitude: 51.50684891859436,
            longitude: -0.07531986216218536
        ),
        distance: 100.0,
        heading: 146.0,
        pitch: 72.0
    )
    london.addAttraction(
        name: "Westminster Abbey",
        address: "20 Deans Yd, London SW1P 3PA",
        coordinate: CLLocationCoordinate2D(
            latitude: 51.499707295670575,
            longitude: -0.12807285506380467
        ),
        distance: 100.0,
        heading: 145.0,
        pitch: 72.0
    )

    var sanFrancisco = City(name: "San Francisco")
    sanFrancisco.addAttraction(
        name: "Alcatraz Island",
        coordinate: CLLocationCoordinate2D(
            latitude: 37.825205932677065,
            longitude: -122.42278138827253
        ),
        distance: 100.0,
        heading: 359.8,
        pitch: 68.0
    )
    sanFrancisco.addAttraction(
        name: "Fishermans Wharf",
        coordinate: CLLocationCoordinate2D(
            latitude: 37.80782748030779,
            longitude: -122.41612457985897
        ),
        distance: 200.0, // TODO: Doesn't zoom properly!
        heading: 335.0,
        pitch: 68.0
    )
    sanFrancisco.addAttraction(
        name: "Golden Gate Bridge",
        coordinate: CLLocationCoordinate2D(
            latitude: 37.82205184534118,
            longitude: -122.48647786835613
        ),
        distance: 800.0,
        heading: 301.0,
        pitch: 72.0
    )

    return [london, sanFrancisco]
}

let cities = setup()
