import SwiftUI

struct CloseButton: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        Button(action: {
            appVM.isSetting = false
            appVM.isSearching = false
        }) {
            Image(systemName: "x.circle")
                .tint(.gray)
                .padding()
        }
    }
}
