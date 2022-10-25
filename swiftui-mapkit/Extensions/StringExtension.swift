import Foundation

extension String: LocalizedError {
    // This allows String values to be thrown.
    public var errorDescription: String? { self }
}
