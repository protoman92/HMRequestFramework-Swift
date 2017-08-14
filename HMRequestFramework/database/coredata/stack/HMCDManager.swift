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
    private let coordinator: NSPersistentStoreCoordinator
    
    public init(constructor: HMCDConstructorType) throws {
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
