import SwiftUI

struct CloseButton: View {
    @StateObject private var appVM = AppViewModel.shared

    var body: some View {
        Button(action: {
            appVM.isLiking = false
            appVM.isSetting = false
            appVM.isSearching = false
        }) {
            Image(systemName: "x.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .tint(.gray)
                .padding()
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton()
    }
}
