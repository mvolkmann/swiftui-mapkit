import SwiftUI

@main
struct MapKitDemoApp: App {
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(vm)
        }
    }
}
