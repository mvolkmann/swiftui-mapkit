import SwiftUI

final class MapSettings: ObservableObject {
    @Published var elevation = "realistic" // other is "flat"
    @Published var emphasis = "default" // other is "muted"
    @Published var type = "hybrid" // other are "standard" and "image"
}
