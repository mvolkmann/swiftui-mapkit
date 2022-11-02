import SwiftUI

/// This is a SwiftUI TextField that includes a clear button that is visible when not empty.
struct MyTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        _text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
            .overlay(alignment: .trailing) {
                if !text.isEmpty {
                    Button(
                        action: { text = "" },
                        label: {
                            Image(systemName: "x.circle")
                                .renderingMode(.template)
                                .foregroundColor(.gray)
                                .padding(.trailing, 10)
                        }
                    )
                }
            }
    }
}
