import Foundation

final class AttractionDecodable: Decodable {
    let area: String
    let distance: Double
    let heading: Double
    let latitude: Double
    let longitude: Double
    let name: String
    let pitch: Double
}
