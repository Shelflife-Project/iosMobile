import SwiftUI
import WebKit

/// A reusable view that loads an image from a URL asynchronously
/// with an in-memory cache to avoid repeated network requests.
/// Supports both raster images (png/jpg) and SVG.
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

// MARK: - Image Load Result

private enum LoadedImage {
    case raster(UIImage)
    case svg(Data)
}

// MARK: - Cached Async Image

private struct CachedAsyncImage: View {
    let url: URL
    let placeholder: String
    let size: CGFloat

    @State private var loadedImage: LoadedImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            switch loadedImage {
            case .raster(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size / 4))
            case .svg(let data):
                SVGView(data: data)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size / 4))
            case nil:
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
        // Check cache first
        if let cached = ImageCache.shared.get(for: url) {
            self.loadedImage = .raster(cached)
            return
        }
        if let cachedSVG = ImageCache.shared.getSVG(for: url) {
            self.loadedImage = .svg(cachedSVG)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let contentType = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type") ?? ""

            if contentType.contains("svg") {
                ImageCache.shared.setSVG(data, for: url)
                self.loadedImage = .svg(data)
            } else if let uiImage = UIImage(data: data) {
                ImageCache.shared.set(uiImage, for: url)
                self.loadedImage = .raster(uiImage)
            }
        } catch {
            // Silently fail — placeholder remains visible
        }
    }
}

// MARK: - SVG View (WKWebView wrapper)

private struct SVGView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { margin: 0; display: flex; align-items: center; justify-content: center; background: transparent; }
            svg { width: 100%; height: 100%; }
        </style>
        </head>
        <body>\(String(data: data, encoding: .utf8) ?? "")</body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - In-Memory Image Cache

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let rasterCache = NSCache<NSURL, UIImage>()
    private let svgCache = NSCache<NSURL, NSData>()

    private init() {
        rasterCache.countLimit = 200
        svgCache.countLimit = 200
    }

    func get(for url: URL) -> UIImage? {
        rasterCache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        rasterCache.setObject(image, forKey: url as NSURL)
    }

    func getSVG(for url: URL) -> Data? {
        svgCache.object(forKey: url as NSURL) as Data?
    }

    func setSVG(_ data: Data, for url: URL) {
        svgCache.setObject(data as NSData, forKey: url as NSURL)
    }
}

// MARK: - URL Helpers

extension APIService {
    func productIconURL(productId: Int) -> URL? {
        normalizeURL("api/products/\(productId)/icon")
    }

    func userPfpURL(userId: Int) -> URL? {
        normalizeURL("api/users/\(userId)/pfp")
    }
}
