import SwiftUI

@main
struct MapKitDemo: App {
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(vm)
        }
    }
}
