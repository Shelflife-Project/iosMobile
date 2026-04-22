import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .appShadow()
    }
}

extension View {
    func appCard() -> some View {
        AppCard { self }
    }
}
