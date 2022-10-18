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
                        vm.places = await vm.search(text: searchText)
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
                            Text("\(place.displayName)").fontWeight(.bold)
                            if let phone = item.phoneNumber {
                                Text("\(phone)")
                            }
                            if let address = place.address {
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
                    Text("\(place.displayName)").fontWeight(.bold)
                    let lat = place.coordinate.latitude
                    let lng = place.coordinate.longitude
                    Text("lat: \(lat), lng: \(lng)")
                }
            }

            if vm.setupComplete {
                Map(
                    coordinateRegion: $vm.region,
                    annotationItems: vm.places,
                    annotationContent: { place in
                        // MapMarker(coordinate: place.coordinate, tint: .blue)

                        // TODO: Why does zooming the map trigger
                        // TODO: multiple warnings that begin with
                        // TODO: "Publishing changes from within view updates"?
                        // TODO: This only happens with MapAnnotation,
                        // TODO: not wth MapMarker.
                        // TODO: See https://stackoverflow.com/questions/73892561/how-to-re-render-swiftui-map-with-mapannotation-without-runtime-warnings-for-un
                        // TODO: and https://stackoverflow.com/questions/74028793/mapannotation-producing-publishing-changes-from-within-view-updates-runtime-warn.
                        MapAnnotation(coordinate: place.coordinate) {
                            Marker(label: place.displayName)
                                .onTapGesture {
                                    print("place = \(place)")
                                    selectedPlace = place
                                }
                        }
                    }
                )
            } else {
                Text("Loading map ...")
                ProgressView()
            }

            Spacer()
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
