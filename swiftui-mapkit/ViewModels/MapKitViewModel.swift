import Combine // for AnyCancellable
import MapKit // This imports CoreLocation.
import SwiftUI

// Add these keys in Info of each target that queries current location:
// Privacy - Location When In Use Usage Description
// Privacy - Location Always and When In Use Usage Description
class MapKitViewModel: NSObject, ObservableObject {
    // MARK: - State

    @Published var center: CLLocationCoordinate2D?
    @Published var currentPlacemark: CLPlacemark?
    @Published var heading = 0.0
    @Published var likedLocations: [String] = []
    @Published var mapView: MKMapView?
    @Published var pitch = 0.0
    @Published var radius = 0.0
    @Published var searchLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlacemark: CLPlacemark?

    static var shared = MapKitViewModel()

    // MARK: - Initializer

    override init() {
        // This must precede the call to super.init.
        completer = MKLocalSearchCompleter()

        super.init()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        // locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        cancellable = $searchQuery.assign(to: \.queryFragment, on: completer)
        completer.delegate = self
        // This prevent getting points of interest like "Buckingham Palace".
        completer.resultTypes = .address
    }

    // MARK: - Properites

    private var cancellable: AnyCancellable?
    private var completer: MKLocalSearchCompleter
    private let locationManager = CLLocationManager()

    var city: String {
        CoreLocationService.city(from: selectedPlacemark)
    }

    var country: String {
        CoreLocationService.country(from: selectedPlacemark)
    }

    var haveMatches: Bool {
        !searchQuery.isEmpty && !searchLocations.isEmpty
    }

    var state: String {
        CoreLocationService.state(from: selectedPlacemark)
    }

    var usingCurrent: Bool {
        selectedPlacemark != nil && selectedPlacemark == currentPlacemark
    }

    // MARK: - Methods

    func isLikedLocation(_ location: String) -> Bool {
        likedLocations.contains(location)
    }

    func likeLocation(_ location: String) {
        likedLocations.append(location)
        likedLocations.sort()
    }

    func select(placemark: CLPlacemark) {
        selectedPlacemark = placemark
        searchQuery = ""
        searchLocations = []

        if let mapView, let location = placemark.location {
            radius = 10000 // TODO: Why does this have no impact?
            mapView.centerCoordinate = location.coordinate
        }
    }

    func unlikeLocation(_ location: String) {
        likedLocations.removeAll(where: { $0 == location })
    }
}

extension MapKitViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // If we already have the placemark, return.
        guard currentPlacemark == nil else { return }

        if let location = locations.first {
            CLGeocoder().reverseGeocodeLocation(
                location
            ) { [weak self] placemarks, error in
                if let error {
                    print("LocationViewModel: error =", error)
                } else if let self {
                    self.currentPlacemark = placemarks?.first
                    self.selectedPlacemark = self.currentPlacemark
                    // Once we have the location, stop trying to update it.
                    self.locationManager.stopUpdatingLocation()
                }
            }
        }
    }
}

extension MapKitViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var locations = completer.results.map { result in
            result.title + ", " + result.subtitle
        }
        locations.sort()
        searchLocations = locations
    }
}
