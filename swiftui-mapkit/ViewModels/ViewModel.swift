import MapKit

// Conforming to NSObject is required in order to conform to
// CLLocationManagerDelegate which is specified in the extension below.
class ViewModel: NSObject, ObservableObject {
    @Published var isConfiguring: Bool = false
    @Published var isSearching: Bool = false
    @Published var places: [Place] = []
    @Published var region = MKCoordinateRegion()
    @Published var selectedPlace: Place?
    @Published var setupComplete = false

    static let initialPlaces = [
        "Buckingham Palace",
        "Kensington Palace",
        "Tower of London",
        "Westminster Abbey"
    ]

    let manager = CLLocationManager()

    let size = 4000.0 // of area to display in meters

    @MainActor
    override init() {
        super.init()

        // TODO: Why does setting manager properties trigger the warning
        // TODO: "Publishing changes from within view updates"?
        manager.delegate = self
        // Won't find current location without this.
        // It fails to find the current location when this is 20 or below!
        manager.desiredAccuracy = 25 // in meters

        Task { await setup() }
    }

    @MainActor
    func search(text: String, exact: Bool = false) async -> [Place] {
        selectedPlace = nil

        var newPlaces: [Place] = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = region // only searches in this region
        let search = MKLocalSearch(request: request)

        if let results = try? await search.start() {
            for item in results.mapItems {
                let placemark = item.placemark
                // print("category = \(item.pointOfInterestCategory?.rawValue ?? "none")")
                if !exact || placemark.name == text {
                    if let coordinate = placemark.location?.coordinate {
                        let place = Place(item: item, coordinate: coordinate)
                        newPlaces.append(place)
                    }
                }
            }
        }

        return newPlaces
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

        var initialPlaces: [Place] = []

        // TODO: Run these searches in parallel?
        for place in Self.initialPlaces {
            let newPlaces = await search(text: place, exact: true)
            initialPlaces += newPlaces
        }

        // The map is not rendered until this assignment is made.
        // This prevents multiple warnings that begin with
        // "Publishing changes from within view updates".
        places = initialPlaces

        setupComplete = true
    }
}

extension ViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations _: [CLLocation]
    ) {}

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
