import MapKit
import UIKit

class RouteAnnotationView: MKAnnotationView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        if let annotation = annotation as? RouteAnnotation {
            canShowCallout = false // need this?

            let bounds = CGRect(x: 0, y: 0, width: 105.0, height: 42.0)
            let textView = UITextView(frame: bounds)

            textView.contentInsetAdjustmentBehavior = .automatic
            textView.center = CGPoint(x: 0, y: -frame.size.height / 2)
            textView.textAlignment = NSTextAlignment.justified
            textView.textColor = annotation.foregroundColor
            textView.backgroundColor =
                annotation.backgroundColor.withAlphaComponent(0.5)

            // If the route for this annotation is selected, add a border.
            if annotation.route == MapKitViewModel.shared.selectedRoute {
                textView.layer.borderWidth = 2
                textView.layer.borderColor = UIColor.black.cgColor
            }

            let seconds = annotation.route.expectedTravelTime
            let time = seconds.secondsToHMS
            let eta = Date.hoursAndMinutesFromNow(seconds: seconds.int)
            textView.text = "Duration: \(time)\nArrival: \(eta)"

            addSubview(textView)
        }
    }
}
