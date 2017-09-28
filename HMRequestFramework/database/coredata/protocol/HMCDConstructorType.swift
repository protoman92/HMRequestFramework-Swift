//
//  HMCDConstructorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol should be able to construct the
/// necessary CoreData dependencies.
///
/// We use this so that the main HMCDManager is agnostic over the database
/// source (e.g. from a model file or code).
public protocol HMCDConstructorType {
    
    /// Get the associated NSManagedObjectModel.
    ///
    /// - Returns: A NSManagedObjectModel instance.
    /// - Throws: Exception if the model cannot be created.
    func objectModel() throws -> NSManagedObjectModel
    
    /// Get all store settings to added to the coordinator.
    ///
    /// - Returns: An Array of HMPersistentStoreSettings.
    /// - Throws: Exception if the settings are not available.
    func storeSettings() throws -> [HMCDStoreSettings]
    
    /// Get the main context mode to determine the main context to be used.
    ///
    /// - Returns: A HMCDMainContextMode instance.
    func mainContextMode() -> HMCDMainContextMode
}

public extension HMCDConstructorType {
    
    /// Get the associated NSPersistentStoreCoordinate.
    ///
    /// - Returns: A NSPersistentStoreCoordinator.
    /// - Throws: Exception if the coordinator cannot be created.
    public func persistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        let objectModel = try self.objectModel()
        return NSPersistentStoreCoordinator(managedObjectModel: objectModel)
    }
}
