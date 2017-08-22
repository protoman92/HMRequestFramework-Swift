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
/// take a NSManagedObjectContext instance as the first parameter, because in
/// many cases the upper layers need to keep a reference to the context in
/// which data is inserted (otherwise, ARC may deallocate properties). The
/// context that is passed in as parameter should be a blank disposable one
/// created using HMCDManager.disposableObjectContext().
public struct HMCDManager {
    
    /// This context is not accessible outside of this class. It runs in
    /// background thread and acts as root of all managed object contexts.
    let privateContext: NSManagedObjectContext
    
    /// This context is a child of the private managed object context. It runs
    /// concurrently on main thread and should be used strictly for interfacing
    /// with user
    let mainContext: NSManagedObjectContext
    let coordinator: NSPersistentStoreCoordinator
    let settings: [HMCDPersistentStoreSettings]
    
    public init(constructor: HMCDConstructorType) throws {
        let coordinator = try constructor.persistentStoreCoordinator()
        let settings = try constructor.storeSettings()
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
    
    /// Get the main store type. This is useful e.g. when we are doing a
    /// batch delete request and do not want to crash (since it does not work
    /// for InMemory stores).
    ///
    /// - Returns: A StoreType instance.
    public func mainStoreType() -> HMCDPersistentStoreSettings.StoreType? {
        if let type = coordinator.persistentStores.first?.type {
            return HMCDPersistentStoreSettings.StoreType.from(type: type)
        } else {
            return nil
        }
    }
    
    public func isMainStoreTypeInMemory() -> Bool {
        return mainStoreType() == .some(.InMemory)
    }
    
    public func isMainStoreTypeSQLite() -> Bool {
        return mainStoreType() == .some(.SQLite)
    }
    
    /// Apply settings to a store coordinator.
    ///
    /// - Parameters:
    ///   - coordinator: A NSPersistentStoreCoordinator instance.
    ///   - settings: A Sequence of HMCDPersistentStoreSettings.
    /// - Throws: Exception if the settings cannot be applied.
    func applyStoreSettings<S>(_ coordinator: NSPersistentStoreCoordinator,
                               _ settings: S) throws where
        S: Sequence, S.Iterator.Element == HMCDPersistentStoreSettings
    {
        try settings.forEach({
            try coordinator.addPersistentStore(
                ofType: $0.storeType(),
                configurationName: $0.configurationName(),
                at: $0.persistentStoreURL(),
                options: $0.options())
        })
    }
}

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
}

extension HMCDManager: HMCDBlockPerformerType {}
extension HMCDManager: ReactiveCompatible {}
