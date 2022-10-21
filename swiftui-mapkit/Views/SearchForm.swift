import CoreLocation
import MapKit // for MKCoordinateRegionMakeWithDistance
import SwiftUI

struct SearchForm: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var coreLocationVM: CoreLocationViewModel
    @StateObject var mapKitVM = MapKitViewModel.shared

    enum FocusName: Hashable {
        case attractionTextField
        case cityTextField
    }

    @FocusState var focusName: FocusName?

    @State var attractionText = ""

    private var attractionForm: some View {
        // Form { // This adds too much top padding, so using List.
        List {
            Picker("City", selection: $appVM.selectedCity) {
                Text("None").tag(nil as City?)
                ForEach(cities) { city in
                    // Optional() is required for the tag
                    // because the type of selectedCity is optional.
                    Text(city.name).tag(Optional(city))
                }
            }

            if let selectedCity = appVM.selectedCity {
                Picker("Attraction", selection: $appVM.selectedAttraction) {
                    Text("None").tag(nil as Attraction?)
                    ForEach(selectedCity.attractions) { attraction in
                        Text(attraction.name).tag(Optional(attraction))
                    }
                }
                .onChange(of: appVM.selectedAttraction) { attraction in
                    if let attraction {
                        showAttraction(attraction)
                    }
                }
            }
        }
        .listStyle(.plain)
        .frame(height: 100)
    }

    private var matchedLocationList: some View {
        VStack {
            Text("Matched Locations").font(.headline)
            List {
                ForEach(mapKitVM.searchLocations, id: \.self) { location in
                    Button(location) {
                        selectLocation(location)
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 300)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Search by City Name").font(.headline)
                HStack {
                    TextField("City", text: $mapKitVM.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusName, equals: .cityTextField)
                }
                if mapKitVM.haveMatches {
                    matchedLocationList
                }
            }

            VStack(alignment: .leading) {
                Text("Select Attraction").font(.headline)
                attractionForm
            }

            if let mapView = mapKitVM.mapView {
                VStack(alignment: .leading) {
                    Text("Find Nearby").font(.headline)
                    HStack {
                        TextField(
                            "place type like bakery or pizza",
                            text: $attractionText
                        )
                        .textFieldStyle(.roundedBorder)
                        .focused($focusName, equals: .attractionTextField)
                        Button("Search") {
                            focusName = nil
                            Task(priority: .background) {
                                coreLocationVM.places =
                                    await coreLocationVM.search(
                                        mapView: mapView,
                                        text: attractionText
                                    )
                                appVM.isSearching = false
                            }
                        }
                        .disabled(attractionText.isEmpty)
                    }
                }
            }

            Spacer()
        }
        .headerProminence(.increased)
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }

    private func showAttraction(_ attraction: Attraction) {
        guard let mapView = mapKitVM.mapView else { return }

        // This works, but seems to limit the minimum distance.
        let center = CLLocationCoordinate2D(
            latitude: attraction.latitude,
            longitude: attraction.longitude
        )
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: attraction.distance,
            longitudinalMeters: attraction.distance
        )

        mapView.setRegion(region, animated: true)

        mapView.camera.heading = attraction.heading
        mapView.camera.pitch = attraction.pitch

        appVM.isSearching = false
        coreLocationVM.selectedPlace = nil
    }

    private func selectLocation(_ location: String) {
        Task {
            do {
                dismissKeyboard()
                let placemark = try await CoreLocationService
                    .getPlacemark(from: location)
                mapKitVM.select(placemark: placemark)
                appVM.isSearching = false
                coreLocationVM.selectedPlace = nil
            } catch {
                print("SearchForm.selectLocation error:", error)
            }
        }
    }
}
