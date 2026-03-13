import SwiftUI
import Observation

@MainActor
@Observable
final class NotificationsViewModel {
    var animateEnvelope = true

    func triggerAnimations() {
        animateEnvelope = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateEnvelope = false }
        }
    }
}
