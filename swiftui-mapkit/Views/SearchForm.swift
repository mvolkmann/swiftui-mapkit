import SwiftUI

struct SearchForm: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var coreLocationVM: CoreLocationViewModel
    @EnvironmentObject var mapKitVM: MapKitViewModel

    let favoriteLocations = [
        "Las Vegas, Nevada",
        "London, England",
        "Manhattan, New York",
        "Paris, France",
        "San Francisco, California"
    ]

    enum FocusName: Hashable {
        case attractionTextField
        case cityTextField
    }

    @FocusState var focusName: FocusName?

    @State var attractionText = ""

    private var favoritesList: some View {
        List(favoriteLocations, id: \.self) { location in
            Button(location) {
                selectLocation(location)
            }
        }
        .listStyle(.plain)
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
            .frame(maxHeight: .infinity)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Search").font(.title)

            VStack(alignment: .leading) {
                Text("City Search").font(.headline)
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
                Text("Attraction Search in Current City").font(.headline)
                HStack {
                    TextField("Attraction", text: $attractionText)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusName, equals: .attractionTextField)
                    Button("Search") {
                        focusName = nil
                        Task(priority: .background) {
                            coreLocationVM.places = await coreLocationVM
                                .search(text: attractionText)
                            print("places =", coreLocationVM.places)
                            appVM.isSearching = false
                        }
                    }
                    .disabled(attractionText.isEmpty)
                }
            }

            VStack(alignment: .leading) {
                Text("Favorite Cities").font(.headline)
                // TODO: Why does this only show one line?
                // TODO: Maybe you shouldn't use Sections in a List!
                favoritesList
            }

            Spacer()
        }
        .headerProminence(.increased)
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
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
                print("CurrentScreen.selectLocation error:", error)
            }
        }
    }
}
