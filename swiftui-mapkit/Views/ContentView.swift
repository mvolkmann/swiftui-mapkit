import MapKit
import SwiftUI

// TODO: Check for 3D support for other cities including
// TODO: Los Angeles, New York, San Franciso, Philadelphia, San Diego,
// TODO: Washington D.C., Montreal, Toronto, Vancouver, and more.

struct ContentView: View {
    // MARK: - State

    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var coreLocationVM: CoreLocationViewModel
    @EnvironmentObject var mapKitVM: MapKitViewModel

    @State var isBrowsing = false
    @State var url: URL = .init(string: "https://mvolkmann.github.io")!

    static let defaultCoordinate = CLLocationCoordinate2D(
        latitude: 51.501,
        longitude: -0.1425
    )

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
        let location = mapKitVM.selectedPlacemark?.location
        let center = location?.coordinate ?? Self.defaultCoordinate
        return MapView(center: center, zoom: 0.01)
            .edgesIgnoringSafeArea(.bottom)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if let place = coreLocationVM.selectedPlace {
                    placeDetail(place: place)
                }
                if coreLocationVM.setupComplete {
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
                    action: { appVM.isSearching = true },
                    label: { Image(systemName: "magnifyingglass") }
                ),
                trailing: HStack {
                    Button(
                        action: { likeCenter() },
                        label: { Image(systemName: "heart") }
                    )
                    Button(
                        action: { appVM.isSetting = true },
                        label: { Image(systemName: "gearshape") }
                    )
                }
            )
            .onAppear {
                // This work is done here instead of inside the
                // CoreLocationViewModel initializer
                // because the UI needs to be started.
                coreLocationVM.start()
            }
            .sheet(isPresented: $isBrowsing) {
                SafariBrowser(url: $url)
            }
            .sheet(isPresented: $appVM.isSetting) {
                SettingsForm()
            }
            .sheet(isPresented: $appVM.isSearching) {
                SearchForm()
                // .presentationDetents([.height(200)])
            }
        }
    }

    // MARK: - Methods

    private func likeCenter() {
        guard let mapView = mapKitVM.mapView else { return }
        print("mapView =", mapView)
        print("center is", mapView.centerCoordinate)
    }

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
