//
//  Storage.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 03. 13..
//

import Foundation
import Observation

@MainActor
@Observable
class StorageStore {
    var storages: [Storage] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var currentPage = 0
    var pageSize = 0
    var hasNext = false
    var hasPrevious = false

    private let apiService: APIHelper

    init(apiService: APIHelper = .shared) {
        self.apiService = apiService
    }

    func fetch(search: String? = nil, page: Int? = nil, size: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let search { searchText = search }
        if let page { currentPage = max(0, page) }
        if let size { pageSize = max(0, size) }

        do {
            let result = try await apiService.fetchStoragesPage(
                search: searchText,
                size: pageSize,
                page: currentPage
            )
            storages = result.items
            hasNext = result.hasNext
            hasPrevious = result.hasPrevious
            currentPage = result.currentPage
        } catch {
            errorMessage = "Failed to fetch storages: \(error.localizedDescription)"
            storages = []
            hasNext = false
            hasPrevious = false
        }
    }

    func nextPage() async {
        guard hasNext else { return }
        await fetch(page: currentPage + 1)
    }

    func previousPage() async {
        guard hasPrevious else { return }
        await fetch(page: max(0, currentPage - 1))
    }

    func addNew(name: String, currentUser: User?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let newStorage = try await apiService.createStorage(name: name)
            newStorage.owner = newStorage.owner ?? currentUser
            await fetch()
        } catch {
            errorMessage = "Failed to create storage: \(error.localizedDescription)"
        }
    }

    func add(name: String, context: Any? = nil, currentUser: User?) async {
        await addNew(name: name, currentUser: currentUser)
    }

    func updateName(_ storage: Storage, name: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let storageId = storage.serverId else { throw APIError.invalidURL }
            _ = try await apiService.updateStorageName(id: storageId, name: name)
            await fetch()
        } catch {
            errorMessage = "Failed to update storage: \(error.localizedDescription)"
        }
    }

    func remove(_ storage: Storage) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let storageId = storage.serverId {
                try await apiService.deleteStorage(id: storageId)
            }
            storages.removeAll { $0.id == storage.id }
            await fetch()
        } catch {
            errorMessage = "Failed to delete storage: \(error.localizedDescription)"
        }
    }

    func delete(_ storage: Storage, context: Any? = nil) async {
        await remove(storage)
    }

    func leave(_ storage: Storage, context: Any? = nil) async {
        await remove(storage)
    }
}
