import MapKit

class Model: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var annotations: [PlaceAnnotation] = []
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()
    
    let manager = CLLocationManager()
    let size = 1000.0
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = 100
        
        let buckinghamPalace = CLLocationCoordinate2D(
            latitude: 51.501,
            longitude: -0.1425
         )
        let westminsterAbbey = CLLocationCoordinate2D(
            latitude: 51.4993815,
            longitude: -0.1286719
        )
        
        region = MKCoordinateRegion(
            center: buckinghamPalace,
            latitudinalMeters: size,
            longitudinalMeters: size
        )
        
        annotations.append(
            PlaceAnnotation(name: "Queen Shack", location: buckinghamPalace)
        )
        annotations.append(
            PlaceAnnotation(name: "Cemetery", location: westminsterAbbey)
        )
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let coordinates = locations.first?.coordinate {
            annotations.append(
                PlaceAnnotation(name: "Current", location: coordinates)
            )
            /*
            region = MKCoordinateRegion(
                center: coordinates,
                latitudinalMeters: size,
                longitudinalMeters: size
            )
            */
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Error getting current location")
    }
}
