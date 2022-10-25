import CoreLocation
import SwiftUI

struct CoreLocationService {
    static func getPlacemark(from location: CLLocation) async throws
        -> CLPlacemark? {
        try await withCheckedThrowingContinuation { continuation in
            // Cannot call this more than 50 times per second.
            CLGeocoder().reverseGeocodeLocation(location) { placemark, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemark?.first)
                }
            }
        }
    }

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
