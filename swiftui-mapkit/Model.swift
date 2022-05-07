import MapKit

class Model: ObservableObject {
    @Published var annotations: [PlaceAnnotation] = []
    @Published var region: MKCoordinateRegion
    
    
    init() {
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
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        annotations.append(
            PlaceAnnotation(name: "Queen Shack", location: buckinghamPalace)
        )
        annotations.append(
            PlaceAnnotation(name: "Cemetery", location: westminsterAbbey)
        )
    }
}
