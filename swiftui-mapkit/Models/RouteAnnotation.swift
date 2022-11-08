import MapKit

class RouteAnnotation: NSObject, MKAnnotation {
    static let identifier = "route-annotation"

    let coordinate: CLLocationCoordinate2D
    let title: String?
    let route: MKRoute

    init(route: MKRoute) {
        self.route = route
        title = route.name

        let polyline = route.polyline

        // This uses the center of the route bounding rectangle,
        // not a point on the route.
        // coordinate = polyline.coordinate

        // This uses a point near the center of the route.
        let index = polyline.pointCount / 2
        let point = polyline.points()[index]
        coordinate = point.coordinate
    }
}
