import Foundation

extension Double {
    var degreesToRadians: Self { self * .pi / 180.0 }

    var radiansToDegrees: Self { self * 180.0 / .pi }

    func places(_ places: Int) -> String {
        String(format: "%.\(places)f", self)
    }
}
