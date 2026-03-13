//
//  Storage.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 03. 13..
//

import Foundation
import Observation
import SwiftData

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

    func loadLocal(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Storage>(sortBy: [SortDescriptor(\Storage.name)])
            storages = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load storages: \(error.localizedDescription)"
        }
    }

    func fetch(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let remoteStorages = try await apiService.fetchStorages()
            try syncPersistedStorages(remoteStorages, context: context)
            loadLocal(context: context)
        } catch {
            errorMessage = "Failed to fetch storages: \(error.localizedDescription)"
            loadLocal(context: context)
        }
    }

    func add(name: String, context: ModelContext, currentUser: User?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let newStorage = try await apiService.createStorage(name: name)
            if let serverId = newStorage.serverId,
               let existing = try findStorage(byServerId: serverId, context: context) {
                existing.name = newStorage.name
                existing.owner = newStorage.owner
            } else {
                context.insert(newStorage)
            }
            try context.save()
            loadLocal(context: context)
        } catch {
            do {
                let localStorage = Storage(name: name, owner: currentUser)
                context.insert(localStorage)
                try context.save()
                loadLocal(context: context)
            } catch {
                errorMessage = "Failed to create storage: \(error.localizedDescription)"
            }
        }
    }

    func delete(_ storage: Storage, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let storageId = storage.serverId {
                try await apiService.deleteStorage(id: storageId)
            }
            context.delete(storage)
            try context.save()
            storages.removeAll { $0.id == storage.id }
        } catch {
            errorMessage = "Failed to delete storage: \(error.localizedDescription)"
        }
    }

    func leave(_ storage: Storage, context: ModelContext) async {
        await delete(storage, context: context)
    }

    private func syncPersistedStorages(_ remoteStorages: [Storage], context: ModelContext) throws {
        let localStorages = try context.fetch(FetchDescriptor<Storage>())
        var localByServerId: [Int: Storage] = [:]

        for storage in localStorages {
            if let serverId = storage.serverId {
                localByServerId[serverId] = storage
            }
        }

        let remoteServerIds = Set(remoteStorages.compactMap { $0.serverId })

        for remote in remoteStorages {
            guard let remoteId = remote.serverId else { continue }

            if let existing = localByServerId[remoteId] {
                existing.name = remote.name
                existing.owner = remote.owner
            } else {
                context.insert(remote)
            }
        }

        for local in localStorages {
            guard let localId = local.serverId else { continue }
            if !remoteServerIds.contains(localId) {
                context.delete(local)
            }
        }

        try context.save()
    }

    private func findStorage(byServerId serverId: Int, context: ModelContext) throws -> Storage? {
        let descriptor = FetchDescriptor<Storage>()
        return try context.fetch(descriptor).first { $0.serverId == serverId }
    }
}
