import MapKit
import SwiftUI

// TODO: Check for 3D support for other cities including
// TODO: Los Angeles, New York, San Franciso, Philadelphia, San Diego,
// TODO: Washington D.C., Montreal, Toronto, Vancouver, and more.

struct ContentView: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    // MARK: - Properties

    private var loading: some View {
        Group {
            Spacer()
            Text("... loading map ...").font(.largeTitle)
            ProgressView()
                .scaleEffect(x: 2, y: 2, anchor: .center)
                .padding(.top)
        }
    }

    private var title: String {
        appVM.selectedAttraction?.name ?? "Map Explorer"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let place = mapKitVM.selectedPlace {
                    PlaceDetail(place: place)
                }

                // If we have a location to show on the map ...
                if let center = mapKitVM.center {
                    if appVM.isShowingLookAround,
                       let scene = mapKitVM.lookAroundScene {
                        LookAround(scene: scene)
                    } else {
                        // ZStack(alignment: .bottomLeading) {
                        ZStack {
                            // This approach uses UIKit in order to
                            // utilize some cool MapKit features.
                            MapView(center: center, distance: mapKitVM.distance)
                                .edgesIgnoringSafeArea(.bottom)
                            if let image = mapKitVM.lookAroundImage {
                                Button(
                                    action: {
                                        appVM.isShowingLookAround = true
                                    },
                                    label: {
                                        Image(uiImage: image)
                                    }
                                )
                            }
                        }
                    }
                } else {
                    loading
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(
                    action: { appVM.isSearching = true },
                    label: { Image(systemName: "magnifyingglass") }
                ),
                trailing: HStack {
                    Button(
                        action: { appVM.isSaving = true },
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
                // MapKitViewModel initializer because the UI
                // needs to be started in order to request authorization.
                // coreLocationVM.start()
                mapKitVM.start()
            }
            .sheet(isPresented: $appVM.isSaving) {
                SaveAttraction()
            }
            .sheet(isPresented: $appVM.isSetting) {
                SettingsSheet()
            }
            .sheet(isPresented: $appVM.isSearching) {
                SearchSheet()
            }
        }
    }
}
