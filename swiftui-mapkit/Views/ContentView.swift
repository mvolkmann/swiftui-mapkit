import MapKit
import SwiftUI

// TODO: Check for 3D support for other cities including
// TODO: Los Angeles, New York, San Franciso, Philadelphia, San Diego,
// TODO: Washington D.C., Montreal, Toronto, Vancouver, and more.

struct ContentView: View {
    // MARK: - State

    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var coreLocationVM: CoreLocationViewModel
    @StateObject var mapKitVM = MapKitViewModel.shared

    @State var isBrowsing = false

    // This is changed later to the URL of a placemark.
    @State var url: URL = .init(string: "https://mvolkmann.github.io")!

    // MARK: - Properties

    var body: some View {
        NavigationStack {
            VStack {
                if let place = coreLocationVM.selectedPlace {
                    placeDetail(place: place)
                }
                if let center = mapKitVM.center {
                    // This approach uses UIKit in order to
                    // utilize some cool MapKit features.
                    MapView(center: center, radius: mapKitVM.radius)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    Spacer()
                    Text("... loading map ...").font(.largeTitle)
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
                        action: { appVM.isLiking = true },
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
            .sheet(isPresented: $appVM.isLiking) {
                LikeForm()
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
