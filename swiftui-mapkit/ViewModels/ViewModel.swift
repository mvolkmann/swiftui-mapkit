import MapKit

class ViewModel: NSObject, ObservableObject {
    @Published var annotations: [Place] = []
    @Published var region = MKCoordinateRegion()

    static let initialPlaces = [
        "Buckingham Palace",
        "Kensington Palace",
        "Tower of London",
        "Westminster Abbey"
    ]

    let manager = CLLocationManager()

    let size = 4000.0 // of area to display in meters

    var selectedPlace: Place?

    @MainActor
    override init() {
        super.init()

        manager.delegate = self
        // Won't find current location without this.
        // It fails to find the current location when this is 20 or below!
        manager.desiredAccuracy = 25 // in meters

        Task { await setup() }
    }

    @MainActor
    func clearAnnotations() {
        annotations = []
        if let place = selectedPlace { annotations.append(place) }
    }

    func search(_ searchText: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region // only searches in this region
        let search = MKLocalSearch(request: request)

        if let results = try? await search.start() {
            let items = results.mapItems
            await MainActor.run {
                for item in items {
                    let placemark = item.placemark
                    // print("category = \(item.pointOfInterestCategory?.rawValue ?? "none")")
                    if let location = placemark.location?.coordinate {
                        let place = Place(item: item, location: location)
                        // Why does Xcode think I am publishing changes
                        // from within a view update here?
                        // I am inside MainActor.run!
                        annotations.append(place)
                    }
                }
            }
        } else {
            print("no results found")
        }
    }

    @MainActor
    private func setup() async {
        let center = CLLocationCoordinate2D(
            latitude: 51.501,
            longitude: -0.1425
        )
        region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: size,
            longitudinalMeters: size
        )

        for place in Self.initialPlaces {
            await search(place)
        }
    }
}

extension ViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let coordinates = locations.first?.coordinate {
            let location = CLLocation(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            // Guess the address of the current location.
            CLGeocoder().reverseGeocodeLocation(location) { places, _ in
                if let place = places?.first {
                    let placemark = MKPlacemark(placemark: place)
                    let item = MKMapItem(placemark: placemark)
                    item.name = "You Are Here"
                    self.selectedPlace = Place(
                        item: item,
                        location: coordinates
                    )
                } else {
                    self.selectedPlace = Place(
                        name: "You Are Here",
                        location: coordinates
                    )
                }

                Task {
                    await MainActor.run {
                        self.annotations.append(self.selectedPlace!)
                    }
                }
            }
        }
    }

    func locationManager(
        _: CLLocationManager,
        didFailWithError _: Error
    ) {
        print("failed to get current location - user may not have approved")
        // The Simulator cannot get the current location.
        // After the user denies sharing location, they can
        // open their Settings app,  go to Privacy ... Location Services,
        // tap the name of this app, and select
        // Never, Ask Next Time, or While Using the App.
    }
}
