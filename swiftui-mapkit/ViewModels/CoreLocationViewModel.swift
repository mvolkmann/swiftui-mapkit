import MapKit // This imports CoreLocation.

// Conforming to NSObject is required in order to conform to
// CLLocationManagerDelegate which is specified in the extension below.
class CoreLocationViewModel: NSObject, ObservableObject {
    @Published var places: [Place] = []
    @Published var selectedPlace: Place?

    static let initialPlaces = [
        "Buckingham Palace",
        "Kensington Palace",
        "Tower of London",
        "Westminster Abbey"
    ]

    let manager = CLLocationManager()

    let size = 4000.0 // of area to display in meters

    static var shared = CoreLocationViewModel()

    override init() {
        super.init()

        // TODO: Why does setting manager properties trigger the warning
        // TODO: "Publishing changes from within view updates"?
        manager.delegate = self
        // Won't find current location without this.
        // It fails to find the current location when this is 20 or below!
        manager.desiredAccuracy = 25 // in meters

        // TODO: This is only needed to create initial markers in London.
        // Task { await setup() }
    }

    // This searches for points of interest near the current location.
    // Examples include "bakery" and "pizza".
    @MainActor
    func search(
        mapView: MKMapView,
        text: String,
        exact: Bool = false
    ) async -> [Place] {
        selectedPlace = nil

        var newPlaces: [Place] = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = mapView.region // only searches in this region
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [])

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

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
}

// This is used to the the current location of the user.
extension CoreLocationViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }
        let mapKitVM = MapKitViewModel.shared
        mapKitVM.center = location.coordinate
    }

    func locationManager(
        _: CLLocationManager,
        didFailWithError _: Error
    ) {
        print("failed to get current location - user may not have approved")
        // This happens if the Simulator cannot get the current location.
        // If the user denies sharing location, to approve it then must:
        // 1. Opening their Settings app.
        // 2. Go to Privacy ... Location Services.
        // 3. Tap the name of this app.
        // 4. Change the option from "Never" to
        //    "Ask Next Time" or "While Using the App".
    }
}
