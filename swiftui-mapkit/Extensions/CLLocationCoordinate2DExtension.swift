import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    var description: String {
        "lat: \(latitude), lng: \(longitude)"
    }

    public static func == (
        lhs: CLLocationCoordinate2D,
        rhs: CLLocationCoordinate2D
    ) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    /// Returns a Bool that indicates whether a given coordinate is "close" to this one.
    public func isCloseTo(_ other: Self) -> Bool {
        let closeDegrees = 0.1
        let latDiff = abs(latitude - other.latitude)
        let lngDiff = abs(longitude - other.longitude)
        // print("latDiff =", latDiff, ", lngDiff =", lngDiff)
        return latDiff <= closeDegrees && lngDiff <= closeDegrees
    }

    /// Returns the latitude difference in degrees to another coordinate.
    /// - Parameters:
    ///   - to: other CLLocationCoordinate2D
    /// - Returns: difference in degrees
    func latitudeDifference(to: CLLocationCoordinate2D) -> Double {
        to.latitude - latitude
    }

    /// Returns the distance in meters of a latitude range.
    /// - Parameters:
    ///   - degrees: from map bottom to map top in degrees
    /// - Returns: distance in meters
    func latitudeDistance(degrees: Double) -> Double {
        let half = degrees / 2.0
        let top = CLLocation(latitude: latitude - half, longitude: longitude)
        let bottom = CLLocation(latitude: latitude + half, longitude: longitude)
        // The distance method will return zero if the latitude or
        // longitude values are outside of their allowed ranges.
        return top.distance(from: bottom)
    }

    /// Returns the longitude difference in degrees to another coordinate.
    /// - Parameters:
    ///   - to: other CLLocationCoordinate2D
    /// - Returns: difference in degrees
    func longitudeDifference(to: CLLocationCoordinate2D) -> Double {
        to.longitude - longitude
    }

    /// Returns the distance in meters of a longitude range.
    /// - Parameters:
    ///   - degrees: from map left to map right in degrees
    /// - Returns: distance in meters
    func longitudeDistance(degrees: Double) -> Double {
        let half = degrees / 2.0
        let left = CLLocation(latitude: latitude, longitude: longitude - half)
        let right = CLLocation(latitude: latitude, longitude: longitude + half)
        // The distance method will return zero if the latitude or
        // longitude values are outside of their allowed ranges.
        return right.distance(from: left)
    }

    /// Returns the coordinates of point that is at a given offset from this one.
    /// THIS IS NOT CURRENTLY IMPLEMENTED CORRECTLY!
    /// - Parameters:
    ///   - latitudeMeters: latitude offset in meters
    ///   - longitudeMeters: longitude offset in meters
    /// - Returns: coordinates of the offset point
    func offset(
        latitudeMeters _: Double,
        longitudeMeters _: Double
    ) -> CLLocationCoordinate2D {
        let latitude = 0.0
        let longitude = 0.0
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
