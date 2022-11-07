import Foundation

extension String: LocalizedError {
    // This allows String values to be thrown.
    public var errorDescription: String? { self }

    var firstLower: String {
        return prefix(1).lowercased() + dropFirst()
    }

    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
