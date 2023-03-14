import SwiftUI

@main
struct MapExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ErrorViewModel())
        }
    }
}
