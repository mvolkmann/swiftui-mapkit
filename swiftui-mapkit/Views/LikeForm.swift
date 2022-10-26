import SwiftUI

struct LikeForm: View {
    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var isAddingCity = false
    @State private var newAttraction = ""
    @State private var newCity = ""

    enum FocusName: Hashable {
        case attractionTextField
        case cityTextField
    }

    @FocusState var focusName: FocusName?

    private var attractionRow: some View {
        HStack {
            TextField("Attraction", text: $newAttraction)
                .focused($focusName, equals: .attractionTextField)

            Button("Add") {
                guard let mapView = mapKitVM.mapView else { return }

                let center = mapView.centerCoordinate
                let region = mapView.region
                let camera = mapView.camera
                let attraction = Attraction(
                    name: newAttraction,
                    latitude: center.latitude,
                    longitude: center.longitude,
                    radius: region.radius,
                    heading: camera.heading,
                    pitch: camera.pitch
                )
                // TODO: Fix this to allow users to add attractions.
                // selectedCity!.addAttraction(attraction)
            }
        }
    }

    private var mapJSON: String {
        guard let mapView = mapKitVM.mapView else { return "" }

        let region = mapView.region
        let center = region.center
        let camera = mapView.camera
        let decimals = 4

        let json = """
        "latitude": \(center.latitude.places(decimals)),
        "longitude": \(center.longitude.places(decimals)),
        "radius": \(region.radius.places(decimals)),
        "heading": \(Double(camera.heading).places(1)),
        "pitch": \(Double(camera.pitch).places(1))
        """

        // This is printed to the console so it can be
        // manually copied into attractions.json.
        // This won't be needed when the ability to
        // store attractions in Core Data is implemented.
        print("\n" + json)

        return json
    }

    private var selectedAttraction: Attraction? {
        let index = appVM.selectedAttractionIndex
        return index == -1 ? nil : selectedCity?.attractions[index]
    }

    private var selectedCity: City? {
        if newCity.isEmpty {
            let index = appVM.selectedCityIndex
            return index == -1 ? nil : appVM.cities[index]
        } else {
            return City(name: newCity)
        }
    }

    var body: some View {
        List {
            Text("Map JSON").font(.headline)
            Text(mapJSON)
                .padding()
                .border(.gray)

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

            if isAddingCity {
                HStack {
                    TextField("New City/Area", text: $newCity)
                        .focused($focusName, equals: .cityTextField)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        appVM.cities.append(City(name: newCity))
                        // Select the last city.
                        appVM.selectedCityIndex = appVM.cities.count - 1
                        stopAddingCity()
                    }

                    Button(
                        action: { stopAddingCity() },
                        label: {
                            Image(systemName: "x.circle")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .tint(.gray)
                                .padding(.leading)
                        }
                    )
                    // This is needed to prevent a tap on this button
                    // from also triggering a tap on the "Add" button.
                    .buttonStyle(.borderless)
                }
            } else {
                Button("Add City") {
                    isAddingCity = true
                    focusName = .cityTextField
                }
                .buttonStyle(.bordered)
            }

            if appVM.selectedCityIndex != -1 {
                attractionRow
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }

    private func stopAddingCity() {
        dismissKeyboard()
        newCity = ""
        isAddingCity = false
    }
}
