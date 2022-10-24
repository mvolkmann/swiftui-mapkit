import MapKit

public extension MKCoordinateRegion {
    // Computes the radius of a region based on its current span values.
    var radius: CLLocationDistance {
        let latitude = center.latitude
        let longitude = center.longitude
        let latitudeRadius = span.latitudeDelta / 2.0
        let longitudeRadius = span.longitudeDelta / 2.0

        let loc1 = CLLocation(
            latitude: latitude - latitudeRadius,
            longitude: longitude
        )
        let loc2 = CLLocation(
            latitude: latitude + latitudeRadius,
            longitude: longitude
        )
        let loc3 = CLLocation(
            latitude: latitude,
            longitude: longitude - longitudeRadius
        )
        let loc4 = CLLocation(
            latitude: latitude,
            longitude: longitude + longitudeRadius
        )

        let latitudeMeters = loc1.distance(from: loc2)
        print(
            "latitudeDelta =",
            span.latitudeDelta,
            "latitudeMeters =",
            latitudeMeters
        )
        let longitudeMeters = loc3.distance(from: loc4)
        print(
            "longitudeDelta =",
            span.longitudeDelta,
            "longitudeMeters =",
            longitudeMeters
        )
        let radius = min(latitudeMeters, longitudeMeters) / 2.0
        return radius
    }
}
