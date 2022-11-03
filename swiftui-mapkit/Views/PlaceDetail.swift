import MapKit
import SwiftUI

struct PlaceDetail: View {
    @State var isBrowsingWebsite = false

    @State private var loadingDirections = false

    // This is changed later to the URL of a placemark,
    // but we need to initialize it to some valid URL.
    @State var url: URL = .temporaryDirectory

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    let place: Place

    private var directionsButton: some View {
        Button("Directions") {
            Task {
                do {
                    loadingDirections = true
                    try await mapKitVM.loadRouteSteps(place: place)
                    loadingDirections = false
                } catch let error as MKError {
                    switch error.code {
                    case .directionsNotFound:
                        mapKitVM.message = "Directions were not found."
                    case .unknown:
                        mapKitVM.message = "The destination is unknown."
                    case .serverFailure:
                        mapKitVM.message =
                            "Server failure prevented getting directions."
                    case .loadingThrottled:
                        mapKitVM.message = "Getting directions was throttled."
                    case .placemarkNotFound:
                        mapKitVM.message = "The destination was not found."
                    case .decodingFailed:
                        mapKitVM.message = "Direction decoding failed."
                    @unknown default:
                        mapKitVM.message = error.localizedDescription
                    }
                } catch {
                    Log.error("error getting directions: \(error)")
                }

                appVM.isShowingDirections = true
            }
        }
        .buttonStyle(.bordered)
    }

    var body: some View {
        VStack {
            if let item = place.item {
                HStack {
                    VStack(alignment: .leading) {
                        Text(place.displayName).fontWeight(.bold)
                        if let phone = item.phoneNumber {
                            Text(phone)
                        }
                        if let address = place.address {
                            Text(address)
                        }
                    }

                    Spacer()

                    VStack {
                        websiteButton(item: item)
                        if loadingDirections {
                            ProgressView()
                        } else {
                            directionsButton
                        }
                    }
                    .padding(.top, 40) // leaves room from CloseButton
                }
            } else {
                Text(place.displayName).fontWeight(.bold)
                Text("latitude: \(place.coordinate.latitude)")
                Text("longitude: \(place.coordinate.longitude)")
            }
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton {
                mapKitVM.selectedPlace = nil
            }
        }
        .sheet(isPresented: $isBrowsingWebsite) {
            SafariView(url: $url)
        }
        .sheet(isPresented: $appVM.isShowingDirections) {
            Directions()
        }
    }

    @ViewBuilder
    private func websiteButton(item: MKMapItem) -> some View {
        if let itemURL = item.url {
            /*
             // This opens the website of the selected place
             // in Safari.
             Link("Website", destination: itemURL)
             */

            // This opens the website of the selected place
            // in a sheet within this app.
            Button("Website") {
                url = itemURL
                isBrowsingWebsite = true
            }
            .buttonStyle(.bordered)
        } else {
            Text("No website found")
                .fontWeight(.bold)
                .padding(.leading)
        }
    }
}
