import MapKit
import SwiftUI

enum FocusName: Hashable {
    case search
}

private let homeLatitude = 38.7095566
private let homeLongitude = -90.5950477
private let londonLatitude = 51.501
private let londonLongitude = -0.1425

struct ContentView: View {
    // MARK: - State

    @EnvironmentObject var vm: ViewModel

    @FocusState var focusName: FocusName?

    @ObservedObject var mapSettings = MapSettings()

    @State var latitude = londonLatitude
    @State var longitude = londonLongitude
    @State var openWebsite = false
    @State var selectedPlace: Place?
    @State var searchText = ""
    @State var url: URL = .init(string: "https://mvolkmann.github.io")!

    // MARK: - Properties

    private var map: some View {
        /*
         Map(
             coordinateRegion: $vm.region,
             showsUserLocation: true,
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
                         .onTapGesture { selectedPlace = place }
                 }
             }
         )
         */
        ZStack {
            MapView(
                latitude: latitude,
                longitude: longitude,
                zoom: 0.01
            ).environmentObject(mapSettings)
        }
        .overlay(alignment: .bottom) {
            VStack {
                // To tilt the map, changing the view angle,
                // hold two fingers on the map and drag up or down.
                Picker("Map Type", selection: $mapSettings.type) {
                    Text("Standard").tag("standard")
                    Text("Image").tag("image")
                    Text("Hybrid").tag("hybrid") // mix of Standard and Image
                }
                .pickerStyle(.segmented)

                // This doesn't change the map when mapType is Standard,
                // but does for Hybrid and Image.
                Picker("Elevation", selection: $mapSettings.elevation) {
                    Text("Realistic").tag("realistic")
                    Text("Flat").tag("flat")
                }
                .pickerStyle(.segmented)

                Picker("Emphasis", selection: $mapSettings.emphasis) {
                    Text("Default").tag("default")
                    Text("Muted").tag("muted")
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(.white.opacity(0.6))
        }
    }

    private var searchArea: some View {
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
        }
    }

    var body: some View {
        VStack {
            searchArea.padding()
            if let place = selectedPlace {
                placeDetail(place: place)
            }
            if vm.setupComplete {
                map
            } else {
                Text("Loading map ...")
                ProgressView()
            }
            Spacer()
        }
        .onAppear {
            // Requesting access is done here instead of inside the
            // ViewModel initializer because the UI needs to be started.
            vm.manager.requestWhenInUseAuthorization()
            vm.manager.requestLocation()
        }
        .sheet(isPresented: $openWebsite) {
            SafariBrowser(url: $url)
        }
    }

    // MARK: - Methods

    @ViewBuilder
    private func placeDetail(place: Place) -> some View {
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
                        // This opens the website of the selected place
                        // in Safari.
                        Link("Website Outside", destination: itemUrl)

                        // This opens the website of the selected place
                        // in a sheet within this app.
                        Button("Website Inside") {
                            url = itemUrl
                            openWebsite = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            VStack {
                Text("\(place.displayName)").fontWeight(.bold)
                let lat = place.coordinate.latitude
                let lng = place.coordinate.longitude
                Text("lat: \(lat), lng: \(lng)")
            }
        }
    }
}
