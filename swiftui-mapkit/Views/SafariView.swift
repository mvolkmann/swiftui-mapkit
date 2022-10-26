import SafariServices
import SwiftUI

// This is used to display a website inside a sheet within this app
// as opposed to in the Safari app.
struct SafariView: UIViewControllerRepresentable {
    // TODO: Why does this need to be a Binding?
    @Binding var url: URL

    func makeUIViewController(context _: Context) -> some UIViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _: UIViewControllerType,
        context _: Context
    ) {
        // Do nothing.
    }
}
