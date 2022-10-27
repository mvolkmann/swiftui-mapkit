import CoreLocation
import MapKit // for MKCoordinateRegionMakeWithDistance
import SwiftUI

struct SearchForm: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    enum FocusName: Hashable {
        case areaTextField
        case attractionTextField
    }

    @FocusState var focusName: FocusName?

    @State var attractionText = ""

    // MARK: - Properties

    private var attractionForm: some View {
        // Form { // This adds too much top padding, so using List.
        List {
            Picker("City/Area", selection: $appVM.selectedAreaIndex) {
                Text("None").tag(-1)
                let areas = cloudKitVM.areas
                let enumeration = Array(areas.enumerated())
                ForEach(enumeration, id: \.element) { index, area in
                    Text(area.name).tag(index)
                }
            }
            .onChange(of: appVM.selectedAreaIndex) { _ in
                appVM.selectedAttractionIndex = -1
            }

            if let selectedArea {
                Picker(
                    "Attraction",
                    selection: $appVM.selectedAttractionIndex
                ) {
                    Text("None").tag(-1)
                    let enumeration =
                        Array(selectedArea.attractions.enumerated())
                    ForEach(enumeration, id: \.element) { index, attraction in
                        Text(attraction.name).tag(index)
                    }
                }
                .onChange(of: appVM.selectedAttractionIndex) { _ in
                    showAttraction(selectedAttraction)
                }
            }
        }
        .listStyle(.plain)
        // This leaves room for multiline area and attraction values.
        .frame(height: 160)
    }

    private var findNearbyForm: some View {
        HStack {
            TextField(
                "place type like pizza or park",
                text: $attractionText
            )
            .focused($focusName, equals: .attractionTextField)
            Button("Search") {
                focusName = nil
                Task(priority: .background) {
                    mapKitVM.places =
                        await mapKitVM.search(text: attractionText)
                    appVM.isSearching = false
                }
            }
            .disabled(attractionText.isEmpty)
        }
    }

    private var matchedLocationList: some View {
        Group {
            Text("Matched Locations").font(.headline)
            List(mapKitVM.searchLocations, id: \.self) { location in
                Button(location) {
                    selectLocation(location)
                }
            }
            .listStyle(.plain)
            .frame(height: 300)
            // TODO: Why doesn't this work?
            // .frame(maxHeight: .infinity)
        }
    }

    private var selectedArea: Area? {
        let index = appVM.selectedAreaIndex
        return index == -1 ? nil : cloudKitVM.areas[index]
    }

    private var selectedAttraction: Attraction? {
        let index = appVM.selectedAttractionIndex
        return index == -1 ? nil : selectedArea?.attractions[index]
    }

    var body: some View {
        // Get the default background color of Form views.
        let bgColor = Color(UIColor.systemGroupedBackground)

        VStack(spacing: 0) {
            Rectangle()
                .fill(bgColor)
                .frame(maxWidth: .infinity, maxHeight: 20)

            Form {
                Section("Search by City Name") {
                    TextField("City", text: $mapKitVM.searchQuery)
                        .autocorrectionDisabled(true)
                        .focused($focusName, equals: .areaTextField)

                    if mapKitVM.haveMatches {
                        matchedLocationList
                    }
                }

                if !mapKitVM.haveMatches {
                    Section("Select Attraction") {
                        attractionForm
                    }
                }

                if !mapKitVM.haveMatches {
                    Section("Find Nearby") {
                        findNearbyForm
                    }
                }
            }
            .headerProminence(.increased)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }

    // MARK: - Methods

    private func getAttraction(area: String, name: String) -> Attraction? {
        guard let area = cloudKitVM.areas.first(where: { $0.name == area })
        else { return nil }

        return area.attractions.first(where: { $0.name == name })
    }

    private func selectLocation(_ location: String) {
        Task {
            do {
                dismissKeyboard()
                let placemark = try await CoreLocationService
                    .getPlacemark(from: location)
                mapKitVM.select(placemark: placemark)
                stopSearching()
            } catch {
                Log.error(error)
            }
        }
    }

    private func showAttraction(_ attraction: Attraction?) {
        guard let attraction else { return }

        mapKitVM.center = CLLocationCoordinate2D(
            latitude: attraction.latitude,
            longitude: attraction.longitude
        )
        mapKitVM.radius = attraction.radius
        mapKitVM.heading = attraction.heading
        mapKitVM.pitch = attraction.pitch

        stopSearching()
    }

    private func stopSearching() {
        appVM.isSearching = false
        mapKitVM.selectedPlace = nil
    }
}
