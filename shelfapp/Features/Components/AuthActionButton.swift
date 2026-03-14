import SwiftUI

struct AuthActionButton: View {
    let title: String
    let color: Color
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(color)
        .foregroundStyle(.white)
        .cornerRadius(8)
        .disabled(isDisabled)
        .shadow(radius: 4, x: 3, y: 3)
    }
}
