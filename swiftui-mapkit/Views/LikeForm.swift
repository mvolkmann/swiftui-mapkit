import SwiftUI

struct LikeForm: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var isAddingArea = false
    @State private var newArea = ""
    @State private var newAttraction = ""

    enum FocusName: Hashable {
        case areaTextField
        case attractionTextField
    }

    @FocusState var focusName: FocusName?

    // MARK: - Properties

    private var addAreaRow: some View {
        HStack {
            TextField("New City/Area", text: $newArea)
                .focused($focusName, equals: .areaTextField)
                .textFieldStyle(.roundedBorder)

            Button("Add") {
                Task {
                    do {
                        try await cloudKitVM.createArea(name: newArea)
                        // Select the last city.
                        appVM.selectedAreaIndex =
                            cloudKitVM.areas.count - 1
                        stopAddingCity()
                    } catch {
                        Log.error("error adding area: \(error)")
                        stopAddingCity()
                    }
                }
            }
            .disabled(newArea.isEmpty)

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
    }

    private var addAttractionRow: some View {
        HStack {
            TextField("Attraction", text: $newAttraction)
                .focused($focusName, equals: .attractionTextField)

            Button("Add") {
                addAttraction()
            }
            .disabled(newAttraction.isEmpty)
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
        // Login.info("\n" + json)

        return json
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
        List {
            Text("Save Map").font(.headline)
            Text(mapJSON)
                .padding()
                .border(.gray)

            Picker("City/Area", selection: $appVM.selectedAreaIndex) {
                Text("None").tag(-1)
                let enumeration = Array(cloudKitVM.areas.enumerated())
                ForEach(enumeration, id: \.element) { index, area in
                    Text(area.name).tag(index)
                }
            }
            .onChange(of: appVM.selectedAreaIndex) { _ in
                appVM.selectedAttractionIndex = -1
            }

            if isAddingArea {
                addAreaRow
            } else {
                Button("Add City/Area") {
                    isAddingArea = true
                    focusName = .areaTextField
                }
                .buttonStyle(.bordered)
            }

            if appVM.selectedAreaIndex != -1 {
                addAttractionRow
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
    }

    // MARK: - Methods

    private func addAttraction() {
        guard let mapView = mapKitVM.mapView else { return }
        guard let selectedArea else { return }

        let center = mapView.centerCoordinate
        let region = mapView.region
        let camera = mapView.camera
        let cloudKitVM = CloudKitViewModel.shared
        Task {
            do {
                try await cloudKitVM.createAttraction(
                    area: selectedArea.name,
                    name: newAttraction,
                    latitude: center.latitude,
                    longitude: center.longitude,
                    radius: region.radius,
                    heading: camera.heading,
                    pitch: camera.pitch
                )

                // newAttraction = ""
                appVM.isLiking = false // closes sheet
            } catch {
                Log.error("error adding attraction: \(error)")
            }
        }
    }

    private func stopAddingCity() {
        dismissKeyboard()
        newArea = ""
        isAddingArea = false
    }
}
