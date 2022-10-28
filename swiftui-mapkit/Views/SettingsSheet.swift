import SwiftUI
import UniformTypeIdentifiers

// These are settings that affect the map display.
struct SettingsSheet: View {
    // MARK: - State

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var cloudKitVM = CloudKitViewModel.shared

    @State private var isExporting = false
    @State private var isImporting = false

    // MARK: - Properties

    var body: some View {
        VStack {
            Text("Settings").font(.title)

            // To tilt the map, changing the view angle,
            // hold two fingers on the map and drag up or down.
            Picker("Map Type", selection: $appVM.mapType) {
                Text("Standard").tag("standard")
                Text("Image").tag("image")
                Text("Hybrid").tag("hybrid") // mix of Standard and Image
            }
            .pickerStyle(.segmented)

            // This doesn't change the map when mapType is Standard,
            // but does for Hybrid and Image.
            Picker("Elevation", selection: $appVM.mapElevation) {
                Text("Flat").tag("flat")
                // If map type is Image or Standard,
                // the elevation must be set to Realistic to
                // enable changing pitch by dragging two fingers!
                Text("Realistic").tag("realistic")
            }
            .pickerStyle(.segmented)

            Picker("Emphasis", selection: $appVM.mapEmphasis) {
                Text("Default").tag("default")
                Text("Muted").tag("muted")
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Export Attractions") { isExporting = true }
                Button("Import Attractions") { isImporting = true }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .fileExporter(
            isPresented: $isExporting,
            document: getJSON(),
            contentType: .json,
            defaultFilename: "attractions.json",
            onCompletion: checkExport
        )
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: importJSON
        )
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
        .presentationDetents([.height(220)])
    }

    // MARK: - Methods

    private func attractionExists(_ attraction: AttractionDecodable) -> Bool {
        guard let area = cloudKitVM.areas
            .first(where: { $0.name == attraction.area }) else { return false }
        return area.attractions.contains(where: { $0.name == attraction.name })
    }

    private func checkExport(result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            Log.info("saved attractions JSON to \(url)")
        case let .failure(error):
            Log.error("failed to save attractions JSON: \(error)")
        }

        appVM.isSetting = false // closes this sheet
    }

    private func getJSON() -> JSONFile {
        var json = ""

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let attractions = cloudKitVM.areas.flatMap { $0.attractions }
        if let encoded = try? encoder.encode(attractions) {
            json = String(data: encoded, encoding: .utf8) ?? ""
        }

        return JSONFile(json: json)
    }

    private func importJSON(_ result: Result<[URL], Error>) {
        do {
            if let url = try result.get().first,
               url.startAccessingSecurityScopedResource() {
                let json = try String(contentsOf: url, encoding: .utf8)
                guard let data = json.data(using: .utf8) else {
                    throw "failed to create Data from JSON"
                }

                let attractions = try JSONDecoder().decode(
                    [AttractionDecodable].self,
                    from: data
                )

                // Add the imported attractions to the CloudKit database
                // if they do not already exist.
                Task {
                    for attraction in attractions {
                        if !attractionExists(attraction) {
                            try await cloudKitVM.createAttraction(
                                area: attraction.area,
                                name: attraction.name,
                                latitude: attraction.latitude,
                                longitude: attraction.longitude,
                                distance: attraction.distance,
                                heading: attraction.heading,
                                pitch: attraction.pitch
                            )
                        }
                    }

                    // Reload data from the CloudKit database.
                    await cloudKitVM.load()

                    // Force reloading the attraction picker SearchSheet.
                    appVM.selectedArea = nil

                    appVM.isSetting = false // closes this sheet
                }
            }
        } catch {
            Log.error("SettingsSheet.importJSON error: \(error)")
        }
    }
}
