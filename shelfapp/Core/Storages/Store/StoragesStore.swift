import Foundation
import Observation

@MainActor
@Observable
final class StoragesStore {
    var storagesState: Loadable<[Storage]> = .idle
    var searchText = ""
    var currentPage = 0
    var pageSize = 0
    var hasNext = false
    var hasPrevious = false
    var actionError: String?

    // Convenience accessors for pages
    var storages: [Storage] { storagesState.value ?? [] }
    var isLoading: Bool { storagesState.isLoading }
    var errorMessage: String? {
        get { actionError ?? storagesState.error?.localizedDescription }
        set {
            actionError = newValue
            if newValue == nil, case .failed = storagesState { storagesState = .idle }
        }
    }

    init() {}

    func fetch(search: String? = nil, page: Int? = nil, size: Int? = nil) async {
        if storagesState.value == nil { storagesState = .loading }
        if let search { searchText = search }
        if let page { currentPage = max(0, page) }
        if let size { pageSize = max(0, size) }

        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let result = try await StoragesAPI.fetchAllSummaries(token: token, search: searchText, page: currentPage, size: pageSize > 0 ? pageSize : nil)
            storagesState = .loaded(result.data.map { $0.toDomain() })
            hasNext = result.hasNext
            hasPrevious = result.hasPrevious
            currentPage = result.currentPage
        } catch {
            storagesState = .failed(.serverMessage("Failed to fetch storages: \(error.localizedDescription)"))
            hasNext = false
            hasPrevious = false
        }
    }

    func add(name: String, currentUser: User?) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            _ = try await StoragesAPI.create(token: token, name: name)
            await fetch(page: 0)
        } catch {
            actionError = "Failed to create storage: \(error.localizedDescription)"
        }
    }

    func updateName(_ storage: Storage, name: String) async {
        do {
            guard let storageId = storage.id else { throw APIError.invalidURL }
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            _ = try await StoragesAPI.updateName(token: token, id: storageId, name: name)
            await fetch(page: currentPage)
        } catch {
            actionError = "Failed to update storage: \(error.localizedDescription)"
        }
    }

    func remove(_ storage: Storage) async {
        do {
            if let storageId = storage.id {
                guard let token = sharedJWTToken else { throw APIError.unauthorized }
                try await StoragesAPI.delete(token: token, id: storageId)
            }
            await fetch(page: currentPage)
            if storages.isEmpty && currentPage > 0 {
                await fetch(page: 0)
            }
        } catch {
            actionError = "Failed to delete storage: \(error.localizedDescription)"
        }
    }

    func delete(_ storage: Storage) async { await remove(storage) }
    func leave(_ storage: Storage) async { await remove(storage) }

    func nextPage() async {
        guard hasNext else { return }
        await fetch(page: currentPage + 1, size: pageSize)
    }

    func previousPage() async {
        guard hasPrevious else { return }
        await fetch(page: max(0, currentPage - 1), size: pageSize)
    }
}

typealias StorageService = StoragesStore
