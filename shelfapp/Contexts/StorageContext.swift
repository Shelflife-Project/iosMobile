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
class StorageContext {
    var storages: [Storage] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let remoteStorages = try await apiService.fetchStorages()

            for storage in remoteStorages {
                if let storageId = storage.serverId {
                    storage.items = try await apiService.fetchStorageItems(storageId: storageId)
                    storage.shoppingItems = try await apiService.fetchShoppingItems(storageId: storageId)
                }
            }

            storages = remoteStorages.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = "Failed to fetch storages: \(error.localizedDescription)"
            storages = []
        }
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
