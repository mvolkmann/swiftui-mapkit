
import Combine // for AnyCancellable
import CoreLocation
import MapKit
import SwiftUI

// Add these keys in Info of each target that queries current location:
// Privacy - Location When In Use Usage Description
// Privacy - Location Always and When In Use Usage Description
class LocationViewModel: NSObject, ObservableObject {
    // MARK: - State

    @Published var searchLocations: [String] = []
    @Published var currentPlacemark: CLPlacemark?
    @Published var likedLocations: [String] = []
    @Published var searchQuery = ""
    @Published var selectedPlacemark: CLPlacemark?

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
        // Does this prevent getting points of interest like restaurants?
        completer.resultTypes = .address
    }

    // MARK: - Properites

    static let shared = LocationViewModel()

    private var cancellable: AnyCancellable?
    private var completer: MKLocalSearchCompleter
    private let locationManager = CLLocationManager()

    var city: String {
        LocationService.city(from: selectedPlacemark)
    }

    var country: String {
        LocationService.country(from: selectedPlacemark)
    }

    var state: String {
        LocationService.state(from: selectedPlacemark)
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
    }

    func unlikeLocation(_ location: String) {
        likedLocations.removeAll(where: { $0 == location })
    }
}

extension LocationViewModel: CLLocationManagerDelegate {
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

extension LocationViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        /* SAVE THIS FOR AN EXAMPLE OF USING A TaskGroup!
         // Don't search for placemarks unless
         // at least three characters have been entered.
         guard searchQuery.count >= 3 else { return }

         Task {
         do {
         let placemarks = try await getPlacemarks(for: completer.results)
         await MainActor.run { searchPlacemarks = placemarks }
         } catch {
         print("LocationViewModel error:", error)
         }
         }
         */

        var locations = completer.results.map { result in
            result.title + ", " + result.subtitle
        }
        locations.sort()
        searchLocations = locations
    }

    /* SAVE THIS FOR AN EXAMPLE OF USING A TaskGroup!
     private func getPlacemarks(
     for completions: [MKLocalSearchCompletion]
     ) async throws -> [CLPlacemark] {
     try await withThrowingTaskGroup(of: CLPlacemark?.self) { group in
     // Create an array to hold the results.
     var placemarks: [CLPlacemark] = []
     placemarks.reserveCapacity(completions.count)

     // Create a task for each search completion
     // that gets the corresponding placemark.
     for completion in completions {
     group.addTask {
     do {
     // Cannot make more than 50 requests per second!
     return try await LocationService.getPlacemark(
     from: completion.title
     )
     } catch {
     print("LocationViewModel.getPlacemarks error:", error)
     return nil
     }
     }
     }

     // As each task completes, gather the placemarks.
     for try await placemark in group {
     if let placemark {
     placemarks.append(placemark)
     }
     }

     // After all the tasks have completed, sort the placemarks.
     placemarks.sort(by: {
     let description0 = LocationService.description(from: $0)
     let description1 = LocationService.description(from: $1)
     return description0 < description1
     })

     return placemarks
     }
     }
     */
}
