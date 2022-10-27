import SwiftUI

struct SaveAttraction: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var isAddingArea = false
    @State private var isConfirmingDelete = false
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
                .focused($focusName, equals: .areaTextField)
                .textFieldStyle(.roundedBorder)

            Button("Add") {
                Task {
                    do {
                        appVM.selectedArea =
                            try await cloudKitVM.createArea(name: newArea)
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
            TextField("Attraction name", text: $newAttraction)
                .focused($focusName, equals: .attractionTextField)

            Button("Add") {
                addAttraction()
            }
            .disabled(newAttraction.isEmpty)
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        let count = appVM.selectedArea?.attractions.count ?? 0
        let word = count == 1 ? "attraction" : "attractions"
        let message = count == 0 ? "" :
            "This area has \(count) \(word) that will also be deleted."

        Button("Delete Selected Area") {
            isConfirmingDelete = true
        }
        .buttonStyle(.bordered)
        .confirmationDialog(
            "Are you sure you want to delete the selected area?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible,
            actions: {
                Button("Delete", role: .destructive) {
                    deleteSelectedArea()
                }
            },
            message: { Text(message) }
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
        "radius": \(region.radius.places(decimals)),
        "heading": \(Double(camera.heading).places(1)),
        "pitch": \(Double(camera.pitch).places(1))
        """
    }

    var body: some View {
        VStack {
            Text("Save Attraction").font(.title)

            // This is useful for debugging.
            // Text(mapJSON).padding().border(.gray)

            HStack {
                Text("City/Area").font(.headline)
                Spacer()
                Picker("City/Area", selection: $appVM.selectedArea) {
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
                    if appVM.selectedArea != nil {
                        deleteButton
                    }
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
            CloseButton()
        }
        .onAppear {
            // This is printed to the console so it can be
            // manually copied into attractions.json.
            Log.info("\n" + mapJSON)
        }
    }

    // MARK: - Methods

    private func addAttraction() {
        guard let mapView = mapKitVM.mapView else { return }
        guard let selectedArea = appVM.selectedArea else { return }

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

                appVM.isSaving = false // closes sheet
            } catch {
                Log.error("error adding attraction: \(error)")
            }
        }
    }

    private func deleteSelectedArea() {
        guard let area = appVM.selectedArea else { return }
        if !area.attractions.isEmpty {}
        Task {
            do {
                try await cloudKitVM.deleteArea(area)
                appVM.selectedArea = nil
            } catch {
                Log.error(error)
            }
        }
    }

    private func stopAddingCity() {
        dismissKeyboard()
        newArea = ""
        isAddingArea = false
    }
}
