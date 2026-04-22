import Foundation

/// Single source of truth for app-wide configuration.
/// Change the base URL here to switch environments (simulator, physical device, production).
enum AppConfig {
    /// The backend base URL. Change this when testing on a physical device (use your Mac's IP).
    /// - Simulator: `http://localhost:8080`
    /// - Physical device: `http://<your-mac-ip>:8080`
    static let baseURL = "http://localhost:8080"
}
