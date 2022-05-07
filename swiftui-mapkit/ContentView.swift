import MapKit
import SwiftUI

struct Marker: View {
    var label: String
    var icon: String = "mappin.circle.fill"
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
            Text(label).fontWeight(.bold)
        }
        .foregroundColor(.blue)
    }
}

struct ContentView: View {
    @EnvironmentObject var model: Model
    @State var selectedPlace: Place?
    @State var searchText = ""
    
    var body: some View {
        VStack {
            if let place = selectedPlace {
                Text("\(place.showName)")
                Text("\(place.showPhone)")
                Text("\(place.showUrl)")
                Text("\(place.showAddress)")
            }
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Search") {
                    Task(priority: .background) {
                        await performSearch()
                    }
                }
                Spacer()
            }
            .padding()
            Map(
                coordinateRegion: $model.region,
                annotationItems: model.annotations,
                annotationContent: { place in
                    //MapMarker(coordinate: place.location, tint: .blue)
                    MapAnnotation(coordinate: place.location) {
                        Marker(label: place.showName)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                }
            )
        }
        .onAppear {
            model.manager.requestWhenInUseAuthorization()
            model.manager.requestLocation()
        }
    }
    
    func performSearch() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = model.region
        let search = MKLocalSearch(request: request)
        
        if let results = try? await search.start() {
            let items = results.mapItems
            await MainActor.run {
                model.annotations = []
                for item in items {
                    let placemark = item.placemark
                    print("===")
                    print("name = \(item.name ?? "none")")
                    print("phoneNumber = \(item.phoneNumber ?? "none")")
                    print("url = \(item.url?.absoluteString ?? "none")")
                    print("catetgory = \(item.pointOfInterestCategory?.rawValue ?? "none")")
                    if let location = placemark.location?.coordinate {
                        let place = Place(item: item, location: location)
                        model.annotations.append(place)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Model())
    }
}
