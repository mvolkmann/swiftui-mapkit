import SwiftUI

struct SettingsForm: View {
    @EnvironmentObject var appVM: AppViewModel

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
                Text("Realistic").tag("realistic")
                Text("Flat").tag("flat")
            }
            .pickerStyle(.segmented)

            Picker("Emphasis", selection: $appVM.mapEmphasis) {
                Text("Default").tag("default")
                Text("Muted").tag("muted")
            }
            .pickerStyle(.segmented)

            Spacer()
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            CloseButton()
        }
        .presentationDetents([.height(200)])
    }
}
