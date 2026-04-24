import SwiftUI

/// Drives a staggered entrance animation for a fixed number of slots.
///
/// Replaces ad-hoc `DispatchQueue.main.asyncAfter` chains scattered across
/// pages. A slot's `isAnimating` starts `true` and flips to `false` after
/// its staggered delay — mirroring the previous pattern used for SF Symbol
/// `symbolEffect` animations like `.wiggle`, `.drawOn`, and `.bounce`.
@MainActor
@Observable
final class StaggeredAppearance {
    private(set) var flags: [Bool]

    init(slots: Int) {
        self.flags = Array(repeating: true, count: max(slots, 0))
    }

    func isAnimating(_ index: Int) -> Bool {
        guard flags.indices.contains(index) else { return false }
        return flags[index]
    }

    /// Begin the stagger. Each slot fires after `baseDelay + index * step`.
    func trigger(baseDelay: Double = 0.25, step: Double = 0.22) {
        for i in flags.indices { flags[i] = true }
        for index in flags.indices {
            let delay = baseDelay + Double(index) * step
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.55)) {
                    if self.flags.indices.contains(index) {
                        self.flags[index] = false
                    }
                }
            }
        }
    }
}
