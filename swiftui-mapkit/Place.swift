import MapKit

struct Place: Identifiable {
    let id = UUID()
    var selected = false
    var name: String?
    var item: MKMapItem?
    var location: CLLocationCoordinate2D
    
    var showAddress: String {
        guard let place = item?.placemark else { return "unknown" }
        
        let number = place.subThoroughfare ?? ""
        let street = place.thoroughfare ?? "no street"
        let city = place.locality ?? "no city"
        let state = place.administrativeArea ?? ""
        let postalCode = place.postalCode ?? ""
        
        return "\(number) \(street)\n\(city), \(state)\n\(postalCode)"
    }
    
    var showName: String {
        name ?? item?.name ?? "unknown"
    }
    
    var showPhone: String {
        item?.phoneNumber ?? "unknown"
    }
    
    var showUrl: String {
        item?.url?.absoluteString ?? "unknown"
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

