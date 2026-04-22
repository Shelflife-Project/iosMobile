import Foundation

// Written only from @MainActor (AuthStore). Read from async network contexts.
nonisolated(unsafe) var sharedJWTToken: String?