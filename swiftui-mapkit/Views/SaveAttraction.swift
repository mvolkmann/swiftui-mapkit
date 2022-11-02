import SwiftUI

struct SaveAttraction: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var isAddingArea = false
    @State private var isInvalidArea = false
    @State private var isInvalidAttraction = false
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
            TextField("New city/area name", text: $newArea)
                .autocorrectionDisabled(true)
                .focused($focusName, equals: .areaTextField)
                .textFieldStyle(.roundedBorder)

            Button("Add") {
                addArea()
            }
            .disabled(newArea.isEmpty)

            Button(
                action: stopAddingArea,
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
        .alert(
            "Invalid Area Name",
            isPresented: $isInvalidArea,
            actions: {}, // no custom buttons
            message: {
                Text("The city/area name must be unique.")
            }
        )
    }

    private var addAttractionRow: some View {
        HStack {
            TextField("Attraction name", text: $newAttraction)
                .autocorrectionDisabled(true)
                .focused($focusName, equals: .attractionTextField)

            Button("Add") {
                addAttraction()
            }
            .disabled(newAttraction.isEmpty)
        }
        .onAppear {
            focusName = .attractionTextField
        }
        .alert(
            "Invalid Attraction Name",
            isPresented: $isInvalidAttraction,
            actions: {}, // no custom buttons
            message: {
                Text("The attraction name must be unique within its area.")
            }
        )
    }

    private var mapJSON: String {
        guard let mapView = mapKitVM.mapView else { return "" }

        let region = mapView.region
        let center = region.center
        let camera = mapView.camera
        let decimals = 4

        return """
        "latitude": \(center.latitude.places(decimals)),
        "longitude": \(center.longitude.places(decimals)),
        "distance": \(camera.centerCoordinateDistance.places(decimals)),
        "heading": \(angle(camera.heading).places(1)),
        "pitch": \(Double(camera.pitch).places(1))
        """
    }

    var body: some View {
        VStack {
            Text("Save Attraction").font(.title)

            // This is useful for debugging.
            // Text(mapJSON).padding().border(.gray)

            HStack {
                Text("Area").font(.headline)
                Spacer()
                Picker("Area", selection: $appVM.selectedArea) {
                    Text("None").tag(nil as Area?)
                    ForEach(cloudKitVM.areas) { area in
                        Text(area.name).tag(area as Area?)
                    }
                }
                .onChange(of: appVM.selectedArea) { _ in
                    appVM.selectedAttraction = nil
                    focusName = .attractionTextField
                }
            }

            if isAddingArea {
                addAreaRow
            } else {
                HStack {
                    Spacer()
                    Button("New Area") {
                        isAddingArea = true
                        focusName = .areaTextField
                    }
                    .buttonStyle(.bordered)
                }
            }

            if appVM.selectedArea != nil {
                addAttractionRow
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton {
                appVM.isSaving = false
            }
        }
        .onAppear {
            // This is printed to the console so it can be
            // manually copied into attractions.json.
            Log.info("\n" + mapJSON)
        }
    }

    // MARK: - Methods

    private func addArea() {
        guard isUniqueArea(newArea) else {
            isInvalidArea = true
            return
        }

        Task {
            do {
                appVM.selectedArea =
                    try await cloudKitVM.createArea(name: newArea)
            } catch {
                Log.error("error adding area: \(error)")
            }
            stopAddingArea()
        }
    }

    private func addAttraction() {
        guard isUniqueAttraction(newAttraction) else {
            isInvalidAttraction = true
            return
        }

        guard let mapView = mapKitVM.mapView else { return }
        guard let selectedArea = appVM.selectedArea else { return }

        let camera = mapView.camera
        let center = camera.centerCoordinate
        let cloudKitVM = CloudKitViewModel.shared
        Task {
            do {
                try await cloudKitVM.createAttraction(
                    area: selectedArea.name,
                    name: newAttraction,
                    latitude: center.latitude,
                    longitude: center.longitude,
                    distance: camera.centerCoordinateDistance,
                    heading: angle(camera.heading),
                    pitch: camera.pitch
                )

                appVM.isSaving = false // closes sheet
            } catch {
                Log.error("error adding attraction: \(error)")
            }
        }
    }

    private func angle(_ degrees: Double) -> Double {
        degrees == -0.0 ? -degrees : degrees == 360.0 ? 0 : degrees
    }

    private func isUniqueArea(_ name: String) -> Bool {
        !cloudKitVM.areas.contains(where: { $0.name == name })
    }

    private func isUniqueAttraction(_ name: String) -> Bool {
        guard let area = appVM.selectedArea else { return true }
        return !area.attractions.contains(where: { $0.name == name })
    }

    private func stopAddingArea() {
        dismissKeyboard()
        newArea = ""
        isAddingArea = false
    }
}
