import Contacts // for CNPostalAddressFormatter
import MapKit
import SwiftUI

struct Directions: View {
    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    private var address: String? {
        guard let placemark else { return nil }
        guard let address = placemark.postalAddress else { return nil }
        return CNPostalAddressFormatter().string(from: address)
    }

    private var distance: String {
        var d = mapKitVM.travelDistance
        d = mapKitVM.preferMetric ? d.metersToKilometers : d.metersToMiles
        return d.places(1)
    }

    private var name: String {
        mapKitVM.selectedPlace?.displayName ?? "unknown"
    }

    private var placemark: MKPlacemark? {
        mapKitVM.selectedPlace?.item?.placemark
    }

    var body: some View {
        VStack {
            Text("\(name)\nDirections")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top)

            if let address {
                Text(address).padding(.top)
            }

            HStack {
                Text(distance)
                Picker("Distance Unit", selection: $mapKitVM.preferMetric) {
                    Text("Miles").tag(false)
                    Text("KM").tag(true)
                }
                .frame(width: 135)
                .pickerStyle(.segmented)
                .onChange(of: mapKitVM.preferMetric) { _ in
                    mapKitVM.updateRouteSteps(route: mapKitVM.selectedRoute)
                }
            }
            .padding(.horizontal)

            Text("Time: \(mapKitVM.travelSeconds.secondsToHMS)")
            let seconds = mapKitVM.travelSeconds.int
            Text("ETA: \(Date.hoursAndMinutesFromNow(seconds: seconds))")

            if let message = mapKitVM.message {
                Text(message)
                    .padding(.top)
            } else {
                List(mapKitVM.routeSteps, id: \.self) { step in
                    Text(step)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            CloseButton {
                appVM.isShowingDirections = false
            }
        }
    }
}
