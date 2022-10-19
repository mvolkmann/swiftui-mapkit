import SwiftUI

@main
struct MapExplorerApp: App {
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(vm)
        }
    }
}
