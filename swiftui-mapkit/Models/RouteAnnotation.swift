import MapKit

class RouteAnnotation: NSObject, MKAnnotation {
    static let identifier = "route-annotation"

    let backgroundColor: UIColor
    let coordinate: CLLocationCoordinate2D
    let foregroundColor: UIColor
    let route: MKRoute
    let title: String?

    init(route: MKRoute, foregroundColor: UIColor, backgroundColor: UIColor) {
        self.route = route
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
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
