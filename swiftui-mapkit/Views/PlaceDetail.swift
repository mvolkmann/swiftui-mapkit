import SwiftUI

struct PlaceDetail: View {
    @State var isBrowsingWebsite = false

    // This is changed later to the URL of a placemark,
    // but we need to initialize it to some valid URL.
    @State var url: URL = .temporaryDirectory

    let place: Place

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
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 40) // leaves room from CloseButton
                    } else {
                        Text("No website found")
                            .fontWeight(.bold)
                            .padding(.leading)
                    }
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
                MapKitViewModel.shared.selectedPlace = nil
            }
        }
        .sheet(isPresented: $isBrowsingWebsite) {
            SafariView(url: $url)
        }
    }
}
