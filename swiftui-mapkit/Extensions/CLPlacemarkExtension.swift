import CoreLocation

extension CLPlacemark {
    var city: String { locality ?? "" }

    override public var description: String {
        let theCountry = country ?? ""
        if city == "" {
            return state == "" ? theCountry : "\(state), \(theCountry)"
        } else if city == state {
            return "\(city), \(theCountry)"
        } else {
            return "\(city), \(state)"
        }
    }

    var state: String { administrativeArea ?? "" }
}
