import MapKit

struct PlaceAnnotation: Identifiable {
    let id = UUID()
    var selected = false
    var name = ""
    var location: CLLocationCoordinate2D
    
    init(name: String, location: CLLocationCoordinate2D) {
        self.name = name
        self.location = location
    }
}

