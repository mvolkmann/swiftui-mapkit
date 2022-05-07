import MapKit

class Model: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var annotations: [Place] = []
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
            Place(name: "Queen Shack", location: buckinghamPalace)
        )
        annotations.append(
            Place(name: "Cemetery", location: westminsterAbbey)
        )
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        if let coordinates = locations.first?.coordinate {
            annotations.append(
                Place(name: "Current", location: coordinates)
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
        print("failed to get current location - user may not have approved")
        // After user denies, they can open their Settings app,
        // go to Privacy ... Location Services, tap the name of this app,
        // and select Never, Ask Next Time, or While Using the App.
    }
}
