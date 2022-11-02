import MapKit
import SwiftUI

struct LookAround: UIViewControllerRepresentable {
    typealias UIViewControllerType = MKLookAroundViewController

    let scene: MKLookAroundScene

    func makeUIViewController(
        context _: Context
    ) -> MKLookAroundViewController {
        MKLookAroundViewController(scene: scene)
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {
        // Do nothing.
    }
}
