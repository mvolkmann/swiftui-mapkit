import SafariServices
import SwiftUI

struct SafariBrowser: UIViewControllerRepresentable {
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
