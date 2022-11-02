import MapKit

extension MKCoordinateRegion: Equatable {
    public static func == (
        lhs: MKCoordinateRegion,
        rhs: MKCoordinateRegion
    ) -> Bool {
        lhs.center == rhs.center &&
            lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
            lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}
