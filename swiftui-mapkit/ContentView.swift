import MapKit
import SwiftUI

enum FocusName: Hashable {
    case search
}

struct ContentView: View {
    @EnvironmentObject var vm: ViewModel

    @FocusState var focusName: FocusName?

    @State var openWebsite = false
    @State var selectedPlace: Place?
    @State var searchText = ""
    @State var url: URL = .init(string: "https://mvolkmann.github.io")!

    var body: some View {
        VStack {
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .search)
                Button("Search") {
                    vm.clearAnnotations()
                    Task(priority: .background) {
                        await vm.search(searchText)
                    }
                    focusName = nil
                }
                Spacer()
            }
            .padding()

            if let place = selectedPlace {
                if let item = place.item {
                    HStack {
                        VStack {
                            Text("\(place.showName)").fontWeight(.bold)
                            if let phone = item.phoneNumber {
                                Text("\(phone)")
                            }
                            if let address = place.showAddress {
                                Text("\(address)")
                            }
                        }
                        if let itemUrl = item.url {
                            VStack {
                                Link("Website Outside", destination: itemUrl)
                                Button("Website Inside") {
                                    url = itemUrl
                                    openWebsite = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Text("\(place.showName)").fontWeight(.bold)
                    let lat = place.location.latitude
                    let lng = place.location.longitude
                    Text("lat: \(lat), lng: \(lng)")
                }
            }

            Map(
                coordinateRegion: $vm.region,
                annotationItems: vm.annotations,
                annotationContent: { place in
                    // MapMarker(coordinate: place.location, tint: .blue)
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
            vm.manager.requestWhenInUseAuthorization()
            vm.manager.requestLocation()
        }
        .sheet(isPresented: $openWebsite) {
            SafariBrowser(url: $url)
        }
    }
}
