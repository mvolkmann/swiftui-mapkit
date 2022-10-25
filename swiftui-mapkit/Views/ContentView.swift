import MapKit
import SwiftUI

// TODO: Check for 3D support for other cities including
// TODO: Los Angeles, New York, San Franciso, Philadelphia, San Diego,
// TODO: Washington D.C., Montreal, Toronto, Vancouver, and more.

struct ContentView: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var coreLocationVM = CoreLocationViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State var isBrowsingWebsite = false

    // This is changed later to the URL of a placemark,
    // but we need to initialize it to some valid URL.
    @State var url: URL = .temporaryDirectory

    // MARK: - Properties

    var body: some View {
        NavigationStack {
            VStack {
                if let place = coreLocationVM.selectedPlace {
                    placeDetail(place: place)
                }

                // If we have a location to show on the map ...
                if let center = mapKitVM.center {
                    // This approach uses UIKit in order to
                    // utilize some cool MapKit features.
                    MapView(center: center, radius: mapKitVM.radius)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    Spacer()
                    Text("... loading map ...").font(.largeTitle)
                    ProgressView()
                        .scaleEffect(x: 2, y: 2, anchor: .center)
                        .padding(.top)
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
            .sheet(isPresented: $isBrowsingWebsite) {
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
                VStack(alignment: .leading) {
                    Text("\(place.displayName)").fontWeight(.bold)
                    if let phone = item.phoneNumber {
                        Text("\(phone)")
                    }
                    if let address = place.address {
                        Text("\(address)")
                    }
                }
                Spacer()
                if let itemURL = item.url {
                    VStack {
                        Text("Browse Website").font(.headline)

                        // This opens the website of the selected place
                        // in Safari.
                        Link("In Browser", destination: itemURL)

                        // This opens the website of the selected place
                        // in a sheet within this app.
                        Button("In App") {
                            url = itemURL
                            isBrowsingWebsite = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("No website found")
                        .fontWeight(.bold)
                        .padding(.leading)
                }
            }
            .padding(.horizontal)
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
