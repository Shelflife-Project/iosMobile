import SwiftUI

/// A reusable view that loads an image from a URL asynchronously
/// with an in-memory cache to avoid repeated network requests.
/// Raster images (png/jpg) are displayed directly.
/// SVG responses (server placeholders) fall back to the SF Symbol placeholder
/// to avoid WKWebView overhead and simulator console noise.
struct RemoteImage: View {
    let url: URL?
    let placeholder: String
    let size: CGFloat

    init(url: URL?, placeholder: String = "photo", size: CGFloat = 36) {
        self.url = url
        self.placeholder = placeholder
        self.size = size
    }

    var body: some View {
        if let url {
            CachedAsyncImage(url: url, placeholder: placeholder, size: size)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Image(systemName: placeholder)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Cached Async Image

private struct CachedAsyncImage: View {
    let url: URL
    let placeholder: String
    let size: CGFloat

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage = loadedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size / 4))
            } else {
                Image(systemName: placeholder)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(.secondary)
                    .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        if let cached = ImageCache.shared.get(for: url) {
            self.loadedImage = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let contentType = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type") ?? ""

            // SVG responses are server placeholders — fall back to SF Symbol
            if contentType.contains("svg") { return }

            if let image = UIImage(data: data) {
                ImageCache.shared.set(image, for: url)
                self.loadedImage = image
            }
        } catch {
            // Silently fail — placeholder remains visible
        }
    }
}

// MARK: - In-Memory Image Cache

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func get(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

// MARK: - URL Helpers

extension APIService {
    func productIconURL(productId: Int) -> URL? {
        normalizeURL("api/products/\(productId)/icon/small")
    }

    func userPfpURL(userId: Int) -> URL? {
        normalizeURL("api/users/\(userId)/pfp/small")
    }
}
