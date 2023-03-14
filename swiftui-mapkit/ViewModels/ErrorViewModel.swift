import SwiftUI

// This is inspired by the Azam Sharp YouTube video "Presenting Errors
// Globally in SwiftUI Applications" at https://youtu.be/QfDd9GxjFvk .
class ErrorViewModel: ObservableObject {
    @Published var errorOccurred = false
    @Published private var error: Error?
    @Published private var message = ""

    func alert(error: Error? = nil, message: String) {
        if let error { Log.error(error) }
        self.error = error
        self.message = message
        errorOccurred = true
    }

    var text: Text {
        var content = message
        if let error { content += "\n" + error.localizedDescription }
        return Text(content)
    }
}
