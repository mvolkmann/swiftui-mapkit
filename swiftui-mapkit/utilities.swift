import Foundation

func dump(title: String, object: AnyObject) {
    print(title)
    let mirror = Mirror(reflecting: object)
    for property in mirror.children {
        let label = String(describing: property.label)
        print("\(label) = \(property.value)")
    }
}

func mainQ(closure: @escaping () -> Void) {
    Task<Sendable, Error> {
        await MainActor.run {
            closure()
        }
    }
}
