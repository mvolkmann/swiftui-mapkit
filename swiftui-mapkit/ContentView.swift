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
                Text("\(place.showName)").fontWeight(.bold)
                Text("\(place.showPhone)")
                Text("\(place.showUrl)")
                Text("\(place.showAddress)")
            }
            
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Search") {
                    Task(priority: .background) {
                        await model.search(searchText)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Model())
    }
}
