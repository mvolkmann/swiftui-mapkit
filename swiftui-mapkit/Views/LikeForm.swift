import SwiftUI

struct LikeForm: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject var mapKitVM = MapKitViewModel.shared

    @State private var isAddingCity = false
    @State private var newAttraction = ""
    @State private var newCity = ""

    private var mapJSON: String {
        guard let mapView = mapKitVM.mapView else { return "" }

        // YOU ARE NOT CORRECTLY CAPTURING MAP CHANGES BEFORE THIS IS CALLED!
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

            Button(
                action: { isAddingCity = true },
                label: { Image(systemName: "plus.circle") }
            )

            if isAddingCity {
                HStack {
                    TextField("New City/Area", text: $newCity)
                    Button("Add") {
                        appVM.cities.append(City(name: newCity))
                        appVM.selectedCityIndex = appVM.cities.count - 1
                    }
                }
            }

            if selectedCity != nil {
                HStack {
                    TextField("Attraction", text: $newAttraction)
                    Button("Add") {
                        guard let mapView = mapKitVM.mapView else { return }

                        // TODO: This does not get the current mapView settings!
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

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }
}
