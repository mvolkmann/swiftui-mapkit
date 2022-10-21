import CoreLocation
import SwiftUI

struct CoreLocationService {
    static func city(from placemark: CLPlacemark?) -> String {
        placemark?.locality ?? ""
    }

    static func country(from placemark: CLPlacemark?) -> String {
        placemark?.country ?? ""
    }

    static func description(from placemark: CLPlacemark?) -> String {
        guard let placemark else { return "" }
        let city = Self.city(from: placemark)
        let state = Self.state(from: placemark)
        let country = Self.country(from: placemark)
        if city == "" {
            return state == "" ? country : "\(state), \(country)"
        } else if city == state {
            return "\(city), \(country)"
        } else {
            return "\(city), \(state)"
        }
    }

    static func getPlacemark(from location: CLLocation) async throws
        -> CLPlacemark? {
        try await withCheckedThrowingContinuation { continuation in
            // Cannot call more than 50 times per second!
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
        try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            // Cannot call more than 50 times per second!
            geocoder.geocodeAddressString(addressString) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let placemark = placemarks?.first {
                    continuation.resume(returning: placemark)
                } else {
                    continuation.resume(throwing: "no placemarks found")
                }
            }
        }
    }

    static func state(from placemark: CLPlacemark?) -> String {
        placemark?.administrativeArea ?? ""
    }
}
