import UIKit

/// Central haptic feedback helpers.
///
/// Use semantic helpers (`.tap`, `.success`, etc.) by default — they encode
/// intent and keep the vibration vocabulary consistent across the app.
enum Haptics {

    // MARK: - Raw generators

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }

    static func selection() {
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }

    // MARK: - Semantic helpers

    /// Light tick used on card/row taps and navigation pushes.
    static func tap() { impact(.light) }

    /// Medium tap used on primary actions (save, create, confirm).
    static func action() { impact(.medium) }

    /// Sharp tap for destructive / warning interactions (delete, leave).
    static func destructive() { impact(.rigid) }

    /// Soft tick on toggles and segmented changes.
    static func toggle() { selection() }

    /// Fires `.success` on create/save completion.
    static func success() { notification(.success) }

    /// Fires `.warning` when a destructive confirmation is needed.
    static func warning() { notification(.warning) }

    /// Fires `.error` on a failed action.
    static func failure() { notification(.error) }
}
