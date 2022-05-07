import MapKit

struct Place: Identifiable {
    let id = UUID()
    var selected = false
    var name: String?
    var item: MKMapItem?
    var location: CLLocationCoordinate2D
    
    var showAddress: String? {
        guard let place = item?.placemark else { return nil }
        
        var address = ""
        if let street = place.thoroughfare {
            if let number = place.subThoroughfare {
                address += number + " "
            }
            address += "\(street)\n"
        }
        
        let city = place.locality ?? "no city"
        let state = place.administrativeArea ?? ""
        let postalCode = place.postalCode ?? ""
        
        return "\(address)\(city), \(state)\n\(postalCode)"
    }
    
    var showName: String {
        name ?? item?.name ?? "unknown"
    }
    
    init(name: String, location: CLLocationCoordinate2D) {
        self.name = name
        self.location = location
    }
    
    init(item: MKMapItem, location: CLLocationCoordinate2D) {
        self.item = item
        self.location = location
    }
}

