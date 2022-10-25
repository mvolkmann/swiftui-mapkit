import CoreLocation
import SwiftUI

struct CoreLocationService {
    static func getPlacemark(from location: CLLocation) async throws
        -> CLPlacemark? {
        // Cannot call this more than 50 times per second.
        let placemarks = try await CLGeocoder()
            .reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            return placemark
        } else {
            throw "no placemarks found"
        }
    }

    // This is not currently used.
    static func getPlacemark(from addressString: String) async throws
        -> CLPlacemark {
        // Cannot call this more than 50 times per second.
        let placemarks = try await CLGeocoder()
            .geocodeAddressString(addressString)
        if let placemark = placemarks.first {
            return placemark
        } else {
            throw "no placemarks found"
        }
    }
}
