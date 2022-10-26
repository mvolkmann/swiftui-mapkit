import MapKit // This imports CoreLocation.

// Conforming to NSObject is required in order to conform to
// CLLocationManagerDelegate which is specified in the extension below.
class CoreLocationViewModel: NSObject, ObservableObject {
    @Published var places: [Place] = []
    @Published var selectedPlace: Place?

    // This is not currently being used.
    static let initialPlaces = [
        "Buckingham Palace",
        "Kensington Palace",
        "Tower of London",
        "Westminster Abbey"
    ]

    private let manager = CLLocationManager()

    static var shared = CoreLocationViewModel()

    override init() {
        super.init()

        manager.delegate = self
        // Won't find current location without this.
        // It fails to find the current location when this is 20 or below!
        manager.desiredAccuracy = 25 // in meters

        // TODO: This is only needed to create initial markers in London.
        // Task { await setup() }
    }

    // This searches for points of interest near the current location.
    // Examples include "pizza" and "park".
    @MainActor
    func search(
        mapView: MKMapView,
        text: String,
        exact: Bool = false // if true, requires exact matches
    ) async -> [Place] {
        selectedPlace = nil

        var newPlaces: [Place] = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = mapView.region // only searches in this region
        let search = MKLocalSearch(request: request)

        if let results = try? await search.start() {
            for item in results.mapItems {
                let placemark = item.placemark
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

    /*
      @MainActor
      private func setup() async {
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
      }
     */

    // This is called by ContentView.
    func start() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

// This is used to get the current user location.
extension CoreLocationViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }

        MapKitViewModel.shared.center = location.coordinate
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        print("""
        CoreLocationViewModel: failed to get current location; \
        user may not have approved
        """)
        // If the user denies sharing location, to approve it they must:
        // 1. Open the Settings app.
        // 2. Go to Privacy ... Location Services.
        // 3. Tap the name of this app.
        // 4. Change the option from "Never" to
        //    "Ask Next Time" or "While Using the App".
    }
}
