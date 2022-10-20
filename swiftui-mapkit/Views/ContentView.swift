import MapKit
import SwiftUI

enum FocusName: Hashable {
    case attractionSearch
    case citySearch
}

// TODO: Check for 3D support for other cities including
// TODO: Los Angeles, New York, San Franciso, Philadelphia, San Diego,
// TODO: Washington D.C., Montreal, Toronto, Vancouver, and more.
private let homeLatitude = 38.7095566
private let homeLongitude = -90.5950477
private let londonLatitude = 51.501
private let londonLongitude = -0.1425

struct ContentView: View {
    // MARK: - State

    @EnvironmentObject var vm: ViewModel

    @FocusState var focusName: FocusName?

    @ObservedObject var mapSettings = MapSettings()

    @State var attractionText = ""
    @State var cityText = ""
    @State var isBrowsing = false
    @State var isConfiguring = false
    @State var isSearching = false
    @State var latitude = londonLatitude
    @State var longitude = londonLongitude
    @State var url: URL = .init(string: "https://mvolkmann.github.io")!

    // MARK: - Properties

    private var map: some View {
        /*
         // This is the SwiftUI approach that does not yet support
         // some cool MapKit features.
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

        // This approach uses UIKit in order to
        // utilize some cool MapKit features.
        MapView(
            latitude: latitude,
            longitude: longitude,
            zoom: 0.01
        )
        .environmentObject(mapSettings)
        .edgesIgnoringSafeArea(.bottom)
    }

    private var searchForm: some View {
        VStack {
            Text("Search").font(.title)

            HStack {
                TextField("City", text: $cityText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .citySearch)
                Button("Search") {
                    focusName = nil
                    Task(priority: .background) {
                        vm.places = await vm.search(text: cityText)
                    }
                }
                .disabled(cityText.isEmpty)
            }

            HStack {
                TextField("Attraction", text: $attractionText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .attractionSearch)
                Button("Search") {
                    focusName = nil
                    Task(priority: .background) {
                        vm.places = await vm.search(text: attractionText)
                    }
                }
                .disabled(attractionText.isEmpty)
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            Button(action: { isSearching = false }) {
                Image(systemName: "x.circle")
            }
        }
    }

    private var settingsForm: some View {
        VStack {
            Text("Settings").font(.title)

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

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            Button(action: { isConfiguring = false }) {
                Image(systemName: "x.circle")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if let place = vm.selectedPlace {
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
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("Map Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(
                    action: { isSearching = true },
                    label: { Image(systemName: "magnifyingglass") }
                ),
                trailing: Button(
                    action: { isConfiguring = true },
                    label: { Image(systemName: "gearshape") }
                )
            )
            .onAppear {
                // Requesting access is done here instead of inside the
                // ViewModel initializer because the UI needs to be started.
                vm.manager.requestWhenInUseAuthorization()
                vm.manager.requestLocation()
            }
            .sheet(isPresented: $isBrowsing) {
                SafariBrowser(url: $url)
            }
            .sheet(isPresented: $isConfiguring) {
                settingsForm
                    .presentationDetents([.height(200)])
            }
            .sheet(isPresented: $isSearching) {
                searchForm
                    .presentationDetents([.height(200)])
            }
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
                            isBrowsing = true
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
