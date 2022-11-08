import MapKit
import UIKit

class RouteAnnotationView: MKAnnotationView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        if let annotation = annotation as? RouteAnnotation {
            canShowCallout = true

            let bounds = CGRect(x: 0, y: 0, width: 105.0, height: 42.0)
            let textView = UITextView(frame: bounds)

            textView.contentInsetAdjustmentBehavior = .automatic
            textView.center = CGPoint(x: 0, y: -frame.size.height / 2)
            textView.textAlignment = NSTextAlignment.justified
            textView.textColor = .black
            textView.backgroundColor = .white.withAlphaComponent(0.6)

            let seconds = annotation.route.expectedTravelTime
            let time = seconds.secondsToHMS
            let eta = Date.hoursAndMinutesFromNow(seconds: seconds.int)
            textView.text = "Duration: \(time)\nArrival: \(eta)"

            addSubview(textView)
        }
    }
}
