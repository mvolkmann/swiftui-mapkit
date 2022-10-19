import MapKit

struct Place: Identifiable {
    let id = UUID()
    var selected = false
    var name: String?
    var item: MKMapItem?
    var coordinate: CLLocationCoordinate2D

    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
    }

    init(item: MKMapItem, coordinate: CLLocationCoordinate2D) {
        self.item = item
        self.coordinate = coordinate
    }

    var address: String? {
        return "\(street)\(city), \(state)\n\(postalCode)"
    }

    var city: String {
        item?.placemark.locality ?? ""
    }

    var country: String {
        item?.placemark.country ?? ""
    }

    var displayName: String {
        name ?? item?.name ?? "unknown"
    }

    var postalCode: String {
        item?.placemark.postalCode ?? ""
    }

    var state: String {
        item?.placemark.administrativeArea ?? ""
    }

    var street: String {
        guard let place = item?.placemark else { return "" }
        guard let street = place.thoroughfare else { return "" }

        if let number = place.subThoroughfare {
            return street + " " + number
        } else {
            return street
        }
    }
}
