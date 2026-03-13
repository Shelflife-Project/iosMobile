//
//  Storage.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 03. 13..
//

import Observation
import SwiftData

@Observable
class StorageContext {
    var storageList: [Storage] = []
    
    func add(name: String, context: ModelContext) async throws{
       
        do {
            let newStorage: Storage = await try APIService.shared.createStorage(name: name)
        } catch {
            throw 
        }
        
        
        
        context.insert(newStorage)
        storageList.append(newStorage)
       
        try? context.save()
    }
   
    func fetch() async throws {
        
    }
    
    func load(contex: ModelContext) throws {
        let descriptor = FetchDescriptor<Storage>()
        storageList = try contex.fetch(descriptor)
    }
    
}
