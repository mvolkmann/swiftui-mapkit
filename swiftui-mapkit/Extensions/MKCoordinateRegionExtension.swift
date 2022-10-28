import MapKit

extension MKCoordinateRegion: Equatable {
    // Computes the radius in meters of a region
    // based on its current MKCoordinateSpan values.
    var distance: CLLocationDistance {
        // The "*Delta" properties in a MKCoordinateSpan object
        // found in the MKCoordinateRegion "span" property are
        // the distance in degrees, not meters, from map edge to edge.

        // The "*Meters" properties in a MKCoordinateRegion object are
        // the distance in meters from the map center to the edge.

        let height = center.latitudeDistance(degrees: span.latitudeDelta)
        let width = center.longitudeDistance(degrees: span.longitudeDelta)
        // TODO: This calculation doesn't match camera.centerCoordinateDistance!
        let result = max(width, height) / 2.0 + 105.0
        // Log.debug("height =", height, "width =", width, "result =", result)
        return result
    }

    public static func == (
        lhs: MKCoordinateRegion,
        rhs: MKCoordinateRegion
    ) -> Bool {
        lhs.center == rhs.center &&
            lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
            lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}
