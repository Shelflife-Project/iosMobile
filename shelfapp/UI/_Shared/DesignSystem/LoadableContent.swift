import SwiftUI

struct LoadableContent<T, LoadedView: View, SkeletonView: View>: View {
    let state: Loadable<T>
    @ViewBuilder var loaded: (T) -> LoadedView
    @ViewBuilder var skeleton: () -> SkeletonView

    init(
        _ state: Loadable<T>,
        @ViewBuilder loaded: @escaping (T) -> LoadedView,
        @ViewBuilder skeleton: @escaping () -> SkeletonView = { DefaultSkeleton() }
    ) {
        self.state = state
        self.loaded = loaded
        self.skeleton = skeleton
    }

    var body: some View {
        switch state {
        case .idle, .loading:
            skeleton()
        case .loaded(let value):
            loaded(value)
        case .failed(let error):
            InlineError(message: error.localizedDescription ?? "Something went wrong")
        }
    }
}

private struct DefaultSkeleton: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<3) { _ in SkeletonRow() }
        }
        .padding(.horizontal, Spacing.base)
    }
}

// Convenience where no custom skeleton is needed
extension LoadableContent where SkeletonView == DefaultSkeleton {
    init(_ state: Loadable<T>, @ViewBuilder loaded: @escaping (T) -> LoadedView) {
        self.init(state, loaded: loaded, skeleton: { DefaultSkeleton() })
    }
}
