//
//  HMCDManager.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// This class is used to manage CoreData-related operations. All operations
/// take a Context instance as the first parameter, because in
/// many cases the upper layers need to keep a reference to the context in
/// which data is inserted (otherwise, ARC may deallocate properties). The
/// context that is passed in as parameter should be a blank disposable one
/// created using HMCDManager.disposableObjectContext().
public struct HMCDManager {
    public typealias Context = NSManagedObjectContext
    
    /// This context is not accessible outside of this class. It runs in
    /// background thread and acts as root of all managed object contexts.
    private let privateContext: Context
    
    /// This context is a child of the private managed object context.
    private let mainContext: Context
    private let coordinator: NSPersistentStoreCoordinator
    let settings: [HMCDStoreSettings]
    
    public init(constructor: HMCDConstructorType) throws {
        let coordinator = try constructor.persistentStoreCoordinator()
        let settings = try constructor.storeSettings()
        let privateContext = Context(concurrencyType: .privateQueueConcurrencyType)
        let mainContext = Context(concurrencyType: .mainQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = coordinator
        mainContext.parent = privateContext
        self.coordinator = coordinator
        self.privateContext = privateContext
        self.mainContext = mainContext
        self.settings = settings
        
        // Apply store settings and initialize data stores. This method can be
        // called again to refresh/reset all data.
        try applyStoreSettings(coordinator, settings)
    }
    
    func storeCoordinator() -> NSPersistentStoreCoordinator {
        return coordinator
    }
    
    /// Get the main store type. This is useful e.g. when we are doing a
    /// batch delete request and do not want to crash (since it does not work
    /// for InMemory stores).
    ///
    /// - Returns: A StoreType instance.
    func allStoreTypes() -> [HMCDStoreSettings.StoreType] {
        return coordinator.persistentStores.map({$0.type})
            .flatMap(HMCDStoreSettings.StoreType.from)
    }
    
    /// Check if all stores are of a certain type.
    ///
    /// - Parameter type: A StoreType instance.
    /// - Returns: A Bool value.
    func allStoresOfType(_ type: HMCDStoreSettings.StoreType) -> Bool {
        return allStoreTypes().all({$0 == type})
    }
    
    public func areAllStoresInMemory() -> Bool {
        return allStoresOfType(.InMemory)
    }
    
    public func areAllStoresSQLite() -> Bool {
        return allStoresOfType(.SQLite)
    }
    
    /// Apply settings to a store coordinator.
    ///
    /// - Parameters:
    ///   - coordinator: A NSPersistentStoreCoordinator instance.
    ///   - settings: A Sequence of HMCDStoreSettings.
    /// - Throws: Exception if the settings cannot be applied.
    func applyStoreSettings<S>(_ coordinator: NSPersistentStoreCoordinator,
                               _ settings: S) throws where
        S: Sequence, S.Iterator.Element == HMCDStoreSettings
    {
        try settings.forEach({
            try coordinator.addPersistentStore(
                ofType: $0.storeType(),
                configurationName: $0.configurationName(),
                at: $0.persistentStoreURL(),
                options: $0.options())
        })
    }
    
    /// This context is used to persist changes to DB.
    ///
    /// - Returns: A Context instance.
    func privateObjectContext() -> Context {
        return privateContext
    }
    
    /// This context is used to store changes before saving to file.
    ///
    /// - Returns: A Context instance.
    public func mainObjectContext() -> Context {
        return mainContext
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A Context instance.
    public func disposableObjectContext() -> Context {
        let mainContext = mainObjectContext()
        let context = Context(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        return context
    }
}

extension HMCDManager: HMCDTypealiasType {}
extension HMCDManager: ReactiveCompatible {}
