import CoreLocation
import MapKit // for MKCoordinateRegionMakeWithDistance
import SwiftUI

struct SearchForm: View {
    // MARK: - State

    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var coreLocationVM: CoreLocationViewModel
    @StateObject var mapKitVM = MapKitViewModel.shared

    enum FocusName: Hashable {
        case attractionTextField
        case cityTextField
    }

    @FocusState var focusName: FocusName?

    @State var attractionText = ""

    // MARK: - Properties

    private var attractionForm: some View {
        // Form { // This adds too much top padding, so using List.
        List {
            Picker("City/Area", selection: $appVM.selectedCityIndex) {
                Text("None").tag(-1)
                let enumeration = Array(appVM.cities.enumerated())
                ForEach(enumeration, id: \.element) { index, city in
                    Text(city.name).tag(index)
                }
            }
            .onChange(of: appVM.selectedCityIndex) { _ in
                appVM.selectedAttractionIndex = -1
            }

            if let selectedCity {
                Picker(
                    "Attraction",
                    selection: $appVM.selectedAttractionIndex
                ) {
                    Text("None").tag(-1)
                    let enumeration =
                        Array(selectedCity.attractions.enumerated())
                    ForEach(enumeration, id: \.element) { index, attraction in
                        Text(attraction.name).tag(index)
                    }
                }
                .onChange(of: appVM.selectedAttractionIndex) { _ in
                    if let selectedAttraction {
                        showAttraction(selectedAttraction)
                    }
                }
            }
        }
        .listStyle(.plain)
        .frame(height: 150)
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

    private var selectedAttraction: Attraction? {
        let index = appVM.selectedAttractionIndex
        return index == -1 ? nil : selectedCity?.attractions[index]
    }

    private var selectedCity: City? {
        let index = appVM.selectedCityIndex
        return index == -1 ? nil : appVM.cities[index]
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

            if !mapKitVM.haveMatches {
                VStack(alignment: .leading) {
                    Text("Select Attraction").font(.headline)
                    attractionForm
                }
            }

            /*
             Button("Test") {
                 if let attraction = getAttraction(
                     city: "San Francisco",
                     name: "Golden Gate Bridge"
                 ) {
                     showAttraction(attraction)
                 } else {
                     print("attraction not found")
                 }
             }
             .buttonStyle(.borderedProminent)
             */

            if !mapKitVM.haveMatches, let mapView = mapKitVM.mapView {
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

    // MARK: - Methods

    private func getAttraction(city: String, name: String) -> Attraction? {
        guard let city = appVM.cities.first(where: { $0.name == city })
        else { return nil }

        return city.attractions.first(where: { $0.name == name })
    }

    private func showAttraction(_ attraction: Attraction) {
        mapKitVM.center = CLLocationCoordinate2D(
            latitude: attraction.latitude,
            longitude: attraction.longitude
        )
        mapKitVM.radius = attraction.radius
        mapKitVM.heading = attraction.heading
        mapKitVM.pitch = attraction.pitch

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
