import MapKit

public extension MKCoordinateRegion {
    // Computes the radius of a region based on its current span values.
    var radius: CLLocationDistance {
        let latitude = center.latitude
        let longitude = center.longitude

        // The *Delta properties in a MKCoordinateSpan object
        // found in the MKCoordinateRegion span property are
        // the distance in degrees, not meters, from map edge to edge.

        // The *Meters properties in a MKCoordinateRegion object are
        // the distance in meters from the map center to the edge.

        let latitudeDegrees = span.latitudeDelta / 2.0
        let top = CLLocation(
            latitude: latitude - latitudeDegrees,
            longitude: longitude
        )
        let bottom = CLLocation(
            latitude: latitude + latitudeDegrees,
            longitude: longitude
        )
        let height = bottom.distance(from: top)

        let longitudeDegrees = span.longitudeDelta / 2.0
        let left = CLLocation(
            latitude: latitude,
            longitude: longitude - longitudeDegrees
        )
        let right = CLLocation(
            latitude: latitude,
            longitude: longitude + longitudeDegrees
        )
        let width = left.distance(from: right)

        let radius = min(width, height) / 2.0
        return radius
    }
}
