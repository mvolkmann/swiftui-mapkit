import SwiftUI
import UniformTypeIdentifiers

struct JSONFile: FileDocument {
    static var readableContentTypes = [UTType.json]

    var json = ""

    init(json: String = "") {
        self.json = json
    }

    // Loads data that was previously saved.
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            json = String(decoding: data, as: UTF8.self)
        }
    }

    // Called when the system wants to write our data to disk.
    func fileWrapper(configuration _: WriteConfiguration) throws
        -> FileWrapper {
        let data = Data(json.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
