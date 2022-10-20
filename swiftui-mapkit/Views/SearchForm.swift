import SwiftUI

struct SearchForm: View {
    @EnvironmentObject var mapSettings: MapSettings
    @EnvironmentObject var vm: ViewModel

    @FocusState var focusName: FocusName?

    @ObservedObject var locationVM = LocationViewModel.shared

    @State var attractionText = ""
    @State var cityText = ""

    private var matchedLocations: some View {
        List {
            ForEach(
                locationVM.searchLocations,
                id: \.self
            ) { location in
                Button(location) {
                    selectLocation(location)
                }
            }
        }
        .listStyle(.plain)
    }

    var body: some View {
        VStack {
            Text("Search").font(.title)

            HStack {
                TextField("City", text: $cityText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .citySearch)
                Button("Search") {
                    focusName = nil
                    Task(priority: .background) {
                        vm.places = await vm.search(text: cityText)
                    }
                }
                .disabled(cityText.isEmpty)
            }

            HStack {
                TextField("Attraction", text: $attractionText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusName, equals: .attractionSearch)
                Button("Search") {
                    focusName = nil
                    Task(priority: .background) {
                        vm.places = await vm.search(text: attractionText)
                    }
                }
                .disabled(attractionText.isEmpty)
            }

            if !locationVM.searchQuery.isEmpty,
               !locationVM.searchLocations.isEmpty {
                VStack {
                    Text("Matched Locations").font(.headline)
                    matchedLocations
                }
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }

    private func selectLocation(_ location: String) {
        Task {
            do {
                let placemark = try await LocationService
                    .getPlacemark(from: location)
                locationVM.select(placemark: placemark)
                dismissKeyboard()
            } catch {
                print("CurrentScreen.selectLocation error:", error)
            }
        }
    }
}
