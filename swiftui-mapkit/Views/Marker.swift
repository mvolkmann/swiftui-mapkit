import SwiftUI

// This is not currently used.
// Was it used for predefined London landmarks?
struct Marker: View {
    var label: String
    var icon: String = "mappin.circle.fill"

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 30, height: 30)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
            Text(label).fontWeight(.bold)
        }
        .foregroundColor(.blue)
    }
}
