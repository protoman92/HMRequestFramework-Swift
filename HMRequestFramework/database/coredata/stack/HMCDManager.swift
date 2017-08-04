//
//  HMCDManager.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

public class HMCDManager {
    
    /// This context is not accessible outside of this class. It runs in
    /// background thread and acts as root of all managed object contexts.
    let privateContext: NSManagedObjectContext
    
    /// This context is a child of the private managed object context. It runs
    /// concurrently on main thread and should be used strictly for interfacing
    /// with user
    let mainContext: NSManagedObjectContext
    private let coordinator: NSPersistentStoreCoordinator
    
    public required init(constructor: HMCDConstructorType) throws {
        let coordinator = try constructor.persistentStoreCoordinator()
        let settings = try constructor.storeSettings()
        
        try settings.forEach({
            try coordinator.addPersistentStore(
                ofType: $0.storeType(),
                configurationName: $0.configurationName(),
                at: $0.persistentStoreURL(),
                options: $0.options())
        })
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = coordinator
        mainContext.parent = privateContext
        self.coordinator = coordinator
        self.privateContext = privateContext
        self.mainContext = mainContext
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Throws: Exception if the save fails.
    public func persistChangesToFileUnsafely() throws {
        try saveUnsafely(privateContext)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    public func blockingFetch<Val>(_ request: NSFetchRequest<Val>) throws -> [Val] {
        return try blockingFetch(mainObjectContext(), request)
    }
}

extension HMCDManager: HMCDManagerType {}

extension HMCDManager {

    /// This context is used to store changes before saving to file.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func mainObjectContext() -> NSManagedObjectContext {
        return mainContext
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func disposableObjectContext() -> NSManagedObjectContext {
        let mainContext = mainObjectContext()
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        return context
    }
    
    /// Get the default context to fetch data.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func defaultFetchContext() -> NSManagedObjectContext {
        return mainObjectContext()
    }
    
    /// Get the default context to create data.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func defaultCreateContext() -> NSManagedObjectContext {
        return disposableObjectContext()
    }
    
    /// Get the default context to delete data.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func defaultDeleteContext() -> NSManagedObjectContext {
        return disposableObjectContext()
    }
}
