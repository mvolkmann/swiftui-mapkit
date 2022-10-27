import CoreLocation
import MapKit // for MKCoordinateRegionMakeWithDistance
import SwiftUI

struct SearchForm: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    enum FocusName: Hashable {
        case address
        case kind
    }

    @FocusState private var focusName: FocusName?

    @State private var kind = ""

    // MARK: - Properties

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
                Text("City/Area").font(.headline)
                Spacer()
                Picker("City/Area", selection: $appVM.selectedAreaIndex) {
                    Text("None").tag(-1)
                    let areas = cloudKitVM.areas
                    let enumeration = Array(areas.enumerated())
                    ForEach(enumeration, id: \.element) { index, area in
                        Text(area.name).tag(index)
                    }
                }
                .onChange(of: appVM.selectedAreaIndex) { _ in
                    appVM.selectedAttraction = nil
                }
            }

            if let selectedArea {
                List {
                    ForEach(selectedArea.attractions) { attraction in
                        Button(attraction.name, action: {})
                            .onTapGesture {
                                print("got tap")
                                showAttraction(attraction)
                            }
                    }
                    .onDelete { offsets in
                        Task {
                            do {
                                try await cloudKitVM.deleteAttractions(
                                    area: selectedArea,
                                    offsets: offsets
                                )
                            } catch {
                                Log.error(error)
                            }
                        }
                    }
                }
                .listStyle(.plain)
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

    private var selectedArea: Area? {
        let index = appVM.selectedAreaIndex
        return index == -1 ? nil : cloudKitVM.areas[index]
    }

    var body: some View {
        VStack {
            Text("Search By").font(.title)

            Picker("Search By", selection: $appVM.searchBy) {
                Text("Address").tag("address")
                Text("Attraction").tag("attraction")
                Text("Place Kind").tag("kind")
            }
            .pickerStyle(.segmented)

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
