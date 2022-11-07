import Foundation

extension Double {
    var degreesToRadians: Self { self * .pi / 180.0 }

    var int: Int {
        Int(rounded())
    }

    var metersToKilometers: Double {
        self / 1000
    }

    var metersToMiles: Double {
        self * 0.000621371
    }

    func places(_ places: Int) -> String {
        String(format: "%.\(places)f", self)
    }

    var radiansToDegrees: Self { self * 180.0 / .pi }

    var secondsToHMS: String {
        var seconds = int
        var minutes = seconds / 60
        let hours = minutes / 60
        seconds %= 60
        minutes %= 60
        let s = String(format: "%02d", seconds)
        let m = String(format: "%02d", minutes)
        return hours == 0 ? "\(m):\(s)" : "\(hours):\(m):\(s)"
    }
}
