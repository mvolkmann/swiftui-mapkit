import SwiftUI

@main
struct swiftui_mapkitApp: App {
    @StateObject private var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(vm)
        }
    }
}
