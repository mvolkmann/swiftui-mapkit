import SafariServices
import SwiftUI

struct SafariBrowser: UIViewControllerRepresentable {
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
