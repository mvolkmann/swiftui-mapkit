import SwiftUI

final class AppViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var isSetting = false
    @Published var mapElevation = "realistic" // other is "flat"
    @Published var mapEmphasis = "default" // other is "muted"
    @Published var mapType = "hybrid" // other are "standard" and "image"
}
