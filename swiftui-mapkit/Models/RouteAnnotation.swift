import MapKit

class RouteAnnotation: NSObject, MKAnnotation {
    // This property must be key-value observable,
    // which is what the attributes `@objc dynamic` provide.
    @objc dynamic var coordinate =
        CLLocationCoordinate2D(latitude: 37.779_379, longitude: -122.418_433)

    // Required if `canShowCallout` of the MKMapView is set to `true`.
    var title: String? = "test title"

    // Not required
    var subtitle: String? = "test subtitle"

    var canShowCallout = true

    var leftCalloutOffset = CGPoint(x: 0, y: 0)

    // var leftCalloutAccessoryView = RouteCallout(annotation: self)
}

/*
 class RouteCallout: UIView {
     init(annotation _: MKAnnotation) {
          self.annotation = annotation

          super.init(frame: .zero)

          let titleLabel = UILabel(frame: .zero)
          titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
          titleLabel.text = annotation.name
          addSubview(titleLabel)
          titleLabel.translatesAutoresizingMaskIntoConstraints = false
          titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
          titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
              .isActive = true
          titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
              .isActive = true
     }
 }
 */
