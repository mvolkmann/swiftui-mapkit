import CoreLocation
import MapKit // for MKCoordinateRegionMakeWithDistance
import SwiftUI

struct SearchSheet: View {
    // MARK: - State

    @Environment(\.editMode) private var editMode

    enum FocusName: Hashable {
        case address
        case attractionName
        case kind
    }

    @FocusState private var focusName: FocusName?

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var attractionName = ""
    @State private var editingAttraction: Attraction?
    @State private var message = ""

    @State private var kind = ""

    // MARK: - Properties

    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing == true
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
        }
    }

    private var searchByAddress: some View {
        VStack {
            TextField("Address", text: $mapKitVM.searchQuery)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)
                .focused($focusName, equals: FocusName.address)

            if mapKitVM.haveMatches {
                matchedLocationList
            }
        }
        .onAppear { focusName = .address }
    }

    private var searchByAttraction: some View {
        VStack {
            HStack {
                Text("Area").font(.headline)
                Spacer()
                Picker("Area", selection: $appVM.selectedArea) {
                    Text("None").tag(nil as Area?)
                    ForEach(cloudKitVM.areas) { area in
                        Text(area.name).tag(area as Area?)
                    }
                }
                .padding(.bottom)
                .onChange(of: appVM.selectedArea) { _ in
                    appVM.selectedAttraction = nil
                }
            }

            if let area = appVM.selectedArea {
                attractionList(area: area)
            }

            Spacer()
        }
    }

    private var searchByKind: some View {
        HStack {
            TextField("place kind like pizza or park", text: $kind)
                .textFieldStyle(.roundedBorder)
                .focused($focusName, equals: FocusName.kind)

            Button("Search") {
                Task(priority: .background) {
                    mapKitVM.places =
                        await mapKitVM.search(text: kind)
                    appVM.isSearching = false
                }
            }
            .disabled(kind.isEmpty)
        }
        .onAppear { focusName = .kind }
    }

    var body: some View {
        VStack {
            Text("Search By").font(.title)

            Picker("Search By", selection: $appVM.searchBy) {
                Text("Attraction").tag("attraction")
                Text("Address").tag("address")
                Text("Place Kind").tag("kind")
            }
            .pickerStyle(.segmented)

            if !message.isEmpty {
                Text(message).foregroundColor(.red).fontWeight(.bold)
            }

            switch appVM.searchBy {
            case "address":
                searchByAddress
            case "attraction":
                searchByAttraction
            case "kind":
                searchByKind
            default:
                Text("") // should never happen
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton {
                appVM.isSearching = false
            }
        }
    }

    // MARK: - Methods

    private func attractionEdit(_ attraction: Attraction) -> some View {
        HStack {
            TextField("Attraction Name", text: $attractionName)
                .textFieldStyle(.roundedBorder)
                .focused($focusName, equals: .attractionName)
            /*
                .onAppear {
                    focusName = .attractionName
                }
             */

            Button("Rename") {
                print(
                    "renaming \(attraction.name) to \(attractionName)"
                )
                attraction.record["name"] = attractionName
                Task {
                    try? await cloudKitVM.updateItem(attraction)
                    editingAttraction = nil
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func attractionList(area: Area) -> some View {
        VStack {
            EditButton()

            if isEditing {
                Text("Tap an attraction name to edit it.")
            }

            // We need to use List so we can use the onDelete modifier.
            List(selection: $appVM.selectedAttraction) {
                ForEach(area.attractions) { attraction in
                    if isEditing {
                        if attraction == editingAttraction {
                            attractionEdit(attraction)
                        } else {
                            Button(attraction.name, action: {})
                                .tag(attraction)
                                // Button actions don't work when inside a List.
                                .onTapGesture {
                                    editingAttraction = attraction
                                    attractionName = attraction.name
                                    // Delay changing focusName so it
                                    // happens after the TextField is rendered.
                                    DispatchQueue.main.asyncAfter(
                                        deadline: .now() + 0.1
                                    ) {
                                        focusName = .attractionName
                                    }
                                }
                        }
                    } else {
                        Text(attraction.name)
                            .tag(attraction)
                    }
                }
                .onDelete { offsets in
                    deleteAttractions(offsets: offsets)
                }
            }
            .listStyle(.plain)
            .onChange(of: appVM.selectedAttraction) { attraction in
                if !isEditing, let attraction {
                    showAttraction(attraction)
                }
            }
        }
    }

    private func deleteAttractions(offsets: IndexSet) {
        guard let area = appVM.selectedArea else { return }
        Task {
            do {
                try await cloudKitVM.deleteAttractions(
                    area: area,
                    offsets: offsets
                )
            } catch {
                Log.error(error)
            }
        }
    }

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
                appVM.shouldUpdateCamera = true
                mapKitVM.select(placemark: placemark)
                stopSearching()
            } catch CLError.geocodeFoundNoResult {
                message = "Failed to find matching map location."
            } catch {
                message = error.localizedDescription
            }
        }
    }

    private func showAttraction(_ attraction: Attraction?) {
        guard let attraction else { return }

        mapKitVM.center = CLLocationCoordinate2D(
            latitude: attraction.latitude,
            longitude: attraction.longitude
        )
        mapKitVM.distance = attraction.distance
        mapKitVM.heading = attraction.heading
        mapKitVM.pitch = attraction.pitch

        appVM.shouldUpdateCamera = true

        stopSearching()
    }

    private func stopSearching() {
        message = ""
        appVM.isSearching = false
        mapKitVM.selectedPlace = nil
    }
}
