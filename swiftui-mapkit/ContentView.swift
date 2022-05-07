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

enum FocusName: Hashable {
    case search
}

struct ContentView: View {
    @EnvironmentObject var model: Model
    @FocusState var focusName: FocusName?
    @State var selectedPlace: Place?
    @State var searchText = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .search)
                Button("Search") {
                    model.clearAnnotations()
                    Task(priority: .background) {
                        await model.search(searchText)
                    }
                    focusName = nil
                }
                Spacer()
            }
            .padding()
            
            if let place = selectedPlace {
                Text("\(place.showName)").fontWeight(.bold)
                if let item = place.item {
                    if let phone = item.phoneNumber {
                        Text("\(phone)")
                    }
                    if let address = place.showAddress {
                        Text("\(address)")
                    }
                    if let url = item.url {
                        Link("website", destination: url)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    let lat = place.location.latitude
                    let lng = place.location.longitude
                    Text("lat: \(lat), lng: \(lng)")
                }
            }
            
            Map(
                coordinateRegion: $model.region,
                annotationItems: model.annotations,
                annotationContent: { place in
                    //MapMarker(coordinate: place.location, tint: .blue)
                    MapAnnotation(coordinate: place.location) {
                        Marker(label: place.showName)
                            .onTapGesture {
                                print("place = \(place)")
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Model())
    }
}
