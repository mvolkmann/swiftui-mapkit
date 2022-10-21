import SwiftUI

@main
struct MapExplorerApp: App {
    @StateObject private var appVM = AppViewModel()
    @StateObject private var coreLocationVM = CoreLocationViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM)
                .environmentObject(coreLocationVM)
        }
    }
}
