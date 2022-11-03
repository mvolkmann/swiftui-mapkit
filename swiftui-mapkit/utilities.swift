import Foundation

func mainQ(closure: @escaping () -> Void) {
    Task<Sendable, Error> {
        await MainActor.run {
            closure()
        }
    }
}
