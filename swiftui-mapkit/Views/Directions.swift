import SwiftUI

struct Directions: View {
    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    var body: some View {
        let name = mapKitVM.selectedPlace?.displayName ?? "unknown"
        VStack {
            Text("Directions to\n\(name)")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.top)

            if let message = mapKitVM.message {
                Text(message)
                    .padding(.top)
            } else {
                List(mapKitVM.routeSteps, id: \.self) { step in
                    Text(step)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            CloseButton {
                appVM.isShowingDirections = false
            }
        }
    }
}
