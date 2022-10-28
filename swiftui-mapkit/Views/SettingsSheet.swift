import SwiftUI
import UniformTypeIdentifiers

// These are settings that affect the map display.
struct SettingsSheet: View {
    @StateObject private var appVM = AppViewModel.shared

    @State private var isExporting = false
    @State private var isImporting = false

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
                Button("Import Attractions") {
                    isImporting = true
                }
                Button("Export Attractions") {
                    isExporting = true
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false,
            onCompletion: { result in
                do {
                    let urls = try result.get()
                    if let url = urls.first {
                        if url.startAccessingSecurityScopedResource() {
                            print("fileImporter onCompletion: url =", url)
                            let json = try String(
                                contentsOf: url,
                                encoding: .utf8
                            )
                            print("fileImporter onCompletion: json =", json)
                        } else {
                            print("fileImporter onCompletion: cannot access")
                        }
                    } else {
                        print("fileImporter onCompletion: no url")
                    }
                } catch {
                    Log.error("error reading JSON file: \(error)")
                }
            }
        )
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
        // .presentationDetents([.height(200)])
        .presentationDetents([.height(400)])
    }
}
