import SwiftUI

// Shared trailing swipe configuration so list rows behave consistently across pages.
extension View {
    func trailingSwipeActions<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            content()
        }
    }
}

// Reusable swipe button used by pages and row components.
struct SwipeActionButton: View {
    var title: String
    var systemImage: String
    var tint: Color = .accentColor
    var role: ButtonRole? = nil
    var action: () -> Void

    var body: some View {
        Button(role: role) {
            action()
        } label: {
            Label(title, systemImage: systemImage)
        }
        .tint(tint)
    }
}
