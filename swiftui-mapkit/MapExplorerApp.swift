import SwiftUI

@main
struct MapExplorerApp: App {
    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM)
        }
    }
}
