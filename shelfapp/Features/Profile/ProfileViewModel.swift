import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let appVersion = "1.0.0"
    let appName = "Shelf Life"

    func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "N/A"
        }
        return value
    }
}
