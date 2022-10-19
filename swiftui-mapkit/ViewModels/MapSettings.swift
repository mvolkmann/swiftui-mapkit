import SwiftUI

final class MapSettings: ObservableObject {
    @Published var elevation = "realistic"
    @Published var emphasis = "default"
    @Published var type = "hybrid"
}
