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
        
        let center = CLLocationCoordinate2D(
            latitude: 51.501,
            longitude: -0.1425
        )
        region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: size,
            longitudinalMeters: size
        )
        
        Task {
            await search("Buckingham Palace")
            await search("Westminster Abbey")
        }
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
    
    func search(_ searchText: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        let search = MKLocalSearch(request: request)
        
        if let results = try? await search.start() {
            let items = results.mapItems
            await MainActor.run {
                for item in items {
                    let placemark = item.placemark
                    print("===")
                    print("name = \(item.name ?? "none")")
                    print("phoneNumber = \(item.phoneNumber ?? "none")")
                    print("url = \(item.url?.absoluteString ?? "none")")
                    print("catetgory = \(item.pointOfInterestCategory?.rawValue ?? "none")")
                    if let location = placemark.location?.coordinate {
                        let place = Place(item: item, location: location)
                        annotations.append(place)
                    }
                }
            }
        }
    }
}
