import Foundation

extension Double {
    func places(_ places: Int) -> String {
        String(format: "%.\(places)f", self)
    }
}
