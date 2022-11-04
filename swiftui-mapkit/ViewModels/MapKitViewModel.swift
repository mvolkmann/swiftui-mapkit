import Combine // for AnyCancellable
import MapKit // This imports CoreLocation.
import SwiftUI

// Add these keys in the Info tab for each target that queries current location:
// Privacy - Location When In Use Usage Description
// Privacy - Location Always and When In Use Usage Description
final class MapKitViewModel: NSObject, ObservableObject {
    static let defaultDistance = 1000.0 // in meters

    // MARK: - State

    // These four properties define what the map will display.
    @Published var center: CLLocationCoordinate2D?
    @Published var distance = 0.0 // changed in initializer
    @Published var heading = 0.0 // in degrees
    @Published var pitch = 0.0 // in degrees

    @Published var currentPlacemark: CLPlacemark?
    @Published var isShowingLookAround = false
    @Published var likedLocations: [String] = []
    @Published var lookAroundScene: MKLookAroundScene?
    @Published var lookAroundSnapshot: UIImage?
    @Published var mapView: MKMapView?
    @Published var message: String?
    @Published var places: [Place] = [] {
        didSet { showPlaces() }
    }

    @Published var routeSteps: [String] = []
    @Published var searchLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlace: Place?
    @Published var selectedPlacemark: CLPlacemark?
    @Published var shouldUpdateCamera = true
    @Published var transportType: MKDirectionsTransportType = .automobile

    static var shared = MapKitViewModel()

    // MARK: - Initializer

    override init() {
        // This must precede the call to super.init.
        completer = MKLocalSearchCompleter()

        super.init()

        distance = Self.defaultDistance

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        // A new query is started automatically when searchQuery changes.
        cancellable = $searchQuery.assign(to: \.queryFragment, on: completer)

        // This cannot precede the call to super.init.
        completer.delegate = self

        // This specifies the types of search completions to include.
        // Perhaps all are included if this is not specified.
        // completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    // MARK: - Properties

    // This can be used to cancel an active search, but we aren't using it.
    private var cancellable: AnyCancellable?

    private var completer: MKLocalSearchCompleter

    private let locationManager = CLLocationManager()

    var city: String {
        selectedPlacemark?.city ?? ""
    }

    var country: String {
        selectedPlacemark?.country ?? ""
    }

    var haveMatches: Bool {
        !searchQuery.isEmpty && !searchLocations.isEmpty
    }

    var state: String {
        selectedPlacemark?.state ?? ""
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

    func loadRouteSteps(place: Place) async throws {
        mainQ { self.message = nil }

        guard let mapView else { return }

        let endPlacemark = try await CoreLocationService
            .getPlacemark(from: place.coordinate)
        guard let endPlacemark else {
            Log.error("failed to get destination placemark")
            return
        }

        var startPlacemark: MKPlacemark
        // If an attraction is selected, use that as the starting point.
        if let attraction = AppViewModel.shared.selectedAttraction {
            startPlacemark = MKPlacemark(
                coordinate: CLLocationCoordinate2D(
                    latitude: attraction.latitude,
                    longitude: attraction.longitude
                )
            )
        } else {
            // Otherwise use the current user location as the starting point.
            startPlacemark = MKPlacemark(
                coordinate: await mapView.camera.centerCoordinate
            )
        }

        let request = MKDirections.Request()
        request.source =
            MKMapItem(placemark: MKPlacemark(placemark: startPlacemark))
        request.destination =
            MKMapItem(placemark: MKPlacemark(placemark: endPlacemark))
        request.transportType = transportType

        let directions = MKDirections(request: request)

        let response = try await directions.calculate()

        if let route = response.routes.first {
            // Remove all current overlays.
            for overlay in await mapView.overlays {
                await mapView.removeOverlay(overlay)
            }

            // Add a new overlay.
            await mapView.addOverlay(route.polyline)

            await setVisibleRect(
                route.polyline.boundingMapRect,
                inset: 20.0
            )

            mainQ {
                self.routeSteps = route.steps
                    .compactMap { step in
                        let instructions = step.instructions
                        return instructions.isEmpty ? nil : instructions
                    }
            }
        }
    }

    @MainActor
    func lookAroundUpdate() async throws {
        lookAroundScene = nil
        lookAroundSnapshot = nil
        isShowingLookAround = false

        guard let center = mapView?.camera.centerCoordinate else { return }

        let request = MKLookAroundSceneRequest(coordinate: center)

        // If the returned scene is nil,
        // no Look Around is available for the location.
        let scene = try await request.scene
        let snapshot = try await lookAroundSnapshot(scene: scene)

        lookAroundScene = scene
        lookAroundSnapshot = snapshot
        if lookAroundScene == nil {
            isShowingLookAround = false
        }
    }

    private func lookAroundSnapshot(
        scene: MKLookAroundScene?
    ) async throws -> UIImage? {
        guard let scene else { return nil }

        let snapshotOptions = MKLookAroundSnapshotter.Options()
        snapshotOptions.size = CGSize(width: 128, height: 128)

        // Turn off all point of interest labels in the snapshot.
        snapshotOptions.pointOfInterestFilter =
            MKPointOfInterestFilter.excludingAll

        let snapshotter = MKLookAroundSnapshotter(
            scene: scene,
            options: snapshotOptions
        )
        return try await snapshotter.snapshot.image
    }

    // This searches for points of interest near the current location.
    // Examples include "pizza" and "park".
    @MainActor
    func search(
        text: String,
        exact: Bool = false // if true, requires exact matches
    ) async -> [Place] {
        guard let mapView else { return [] }

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

    func select(placemark: CLPlacemark) {
        selectedPlacemark = placemark
        searchQuery = ""
        searchLocations = []

        if let location = placemark.location {
            center = location.coordinate
            distance = Self.defaultDistance
        }
    }

    private func setVisibleRect(_ rect: MKMapRect, inset: Double) async {
        guard let mapView else { return }

        let insets = UIEdgeInsets(
            top: inset, left: inset, bottom: inset, right: inset
        )
        // This removes the heading and pitch from the camera.
        await mapView.setVisibleMapRect(
            rect,
            edgePadding: insets,
            animated: true
        )
    }

    private func showPlaces() {
        guard !places.isEmpty else { return }

        let firstPlace = places.first!
        var minLat = firstPlace.coordinate.latitude
        var minLng = firstPlace.coordinate.longitude
        var maxLat = minLat
        var maxLng = minLng

        // for place in places.removeFirst() {
        for place in places.dropFirst() {
            let lat = place.coordinate.latitude
            let lng = place.coordinate.longitude
            minLat = min(lat, minLat)
            maxLat = max(lat, maxLat)
            minLng = min(lng, minLng)
            maxLng = max(lng, maxLng)
        }

        let upperLeft = MKMapPoint(
            CLLocationCoordinate2D(latitude: maxLat, longitude: minLng)
        )
        let lowerRight = MKMapPoint(
            CLLocationCoordinate2D(latitude: minLat, longitude: maxLng)
        )
        let rect = MKMapRect(
            x: upperLeft.x,
            y: upperLeft.y,
            width: lowerRight.x - upperLeft.x,
            height: lowerRight.y - upperLeft.y
        )
        Task {
            await setVisibleRect(rect, inset: 50.0)
        }
    }

    // This is called by ContentView.
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func unlikeLocation(_ location: String) {
        likedLocations.removeAll(where: { $0 == location })
    }
}

// This is used to get the current user location.
extension MapKitViewModel: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // If we already have the placemark, return.
        guard currentPlacemark == nil else { return }

        if let location = locations.first {
            center = location.coordinate
            CLGeocoder().reverseGeocodeLocation(
                location
            ) { [weak self] placemarks, error in
                if let error {
                    Log.error(error)
                } else if let self {
                    self.currentPlacemark = placemarks?.first
                    self.selectedPlacemark = self.currentPlacemark
                    // Once we have the location, stop trying to update it.
                    self.locationManager.stopUpdatingLocation()
                }
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        Log.error("failed to get current location; user may not have approved")
        // If the user denies sharing location, to approve it they must:
        // 1. Open the Settings app.
        // 2. Go to Privacy ... Location Services.
        // 3. Tap the name of this app.
        // 4. Change the option from "Never" to
        //    "Ask Next Time" or "While Using the App".
    }
}

extension MapKitViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var locations = completer.results.map { result in
            let title = result.title
            let subtitle = result.subtitle
            return subtitle.isEmpty ? title : title + ", " + subtitle
        }
        locations.sort()
        searchLocations = locations
    }
}
