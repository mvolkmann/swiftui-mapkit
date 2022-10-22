import Foundation

// This was derived from Paul Hudson's post at
// https://www.hackingwithswift.com/example-code/system/how-to-decode-json-from-your-app-bundle-the-easy-way
extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from path: String) -> T {
        guard let url = url(forResource: path, withExtension: nil) else {
            fatalError("Failed to locate \(path) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(path) from bundle.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        decoder.keyDecodingStrategy = .useDefaultKeys

        do {
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            fatalError("""
            Failed to decode \(path) from bundle due to missing key \
            '\(key.stringValue)' not found – \(context.debugDescription)
            """)
        } catch let DecodingError.typeMismatch(_, context) {
            fatalError("""
            Failed to decode \(path) from bundle due to type mismatch \
            – \(context.debugDescription)
            """)
        } catch let DecodingError.valueNotFound(type, context) {
            fatalError("""
            Failed to decode \(path) from bundle due to \
            missing \(type) value – \(context.debugDescription)
            """)
        } catch DecodingError.dataCorrupted(_) {
            fatalError("""
            Failed to decode \(path) from bundle because
            it appears to be invalid JSON
            """)
        } catch {
            fatalError("""
            Failed to decode \(path) from bundle: "
            \(error.localizedDescription)
            """)
        }
    }
}
