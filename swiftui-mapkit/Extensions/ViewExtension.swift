import SwiftUI

extension View {
    #if os(iOS)
        @available(iOSApplicationExtension, unavailable)
        func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    #endif

    public func onTap(
        count: Int = 1,
        perform: @escaping () -> Void
    ) -> some View {
        onTapGesture(count: count, perform: perform)
    }
}
