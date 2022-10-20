import SwiftUI

@main
struct MapExplorerApp: App {
    @StateObject private var mapSettings = MapSettings()
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mapSettings)
                .environmentObject(vm)
        }
    }
}
