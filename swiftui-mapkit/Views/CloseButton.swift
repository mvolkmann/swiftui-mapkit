import SwiftUI

struct CloseButton: View {
    @EnvironmentObject var vm: ViewModel

    var body: some View {
        Button(action: {
            vm.isConfiguring = false
            vm.isSearching = false
        }) {
            Image(systemName: "x.circle")
                .tint(.gray)
                .padding()
        }
    }
}
