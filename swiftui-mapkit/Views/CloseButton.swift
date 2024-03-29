import SwiftUI

struct CloseButton: View {
    @StateObject private var appVM = AppViewModel.shared

    var color: Color = .gray

    let onTap: () -> Void

    // var body: some View {
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "x.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .tint(color)
                .padding()
        }
    }
}
