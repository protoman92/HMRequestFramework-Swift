//
//  HMCDRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Request type for CoreData.
public protocol HMCDRequestType: HMDatabaseRequestType {
    
    /// Get the NSManagedObject entity description.
    ///
    /// - Returns: A String value.
    func entityName() throws -> String
    
    /// Get NSPredicate.
    ///
    /// - Returns: A NSPredicate instance.
    func predicate() throws -> NSPredicate
    
    /// Get an Array of NSSortDescriptor.
    ///
    /// - Returns: An Array of NSSortDescriptor.
    func sortDescriptors() throws -> [NSSortDescriptor]
    
    
    /// Get the associated CoreData operation.
    ///
    /// - Returns: A CoreDataOperation instance.
    func operation() throws -> CoreDataOperation
    
    /// Get the context to perform a save/delete operation. The context should
    /// contain changes to be modified from memory.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    /// - Throws: Exception if the context is not available.
    func contextToSave() throws -> NSManagedObjectContext
    
    /// Get the data to be upserted. Only used with upsert operations.
    ///
    /// - Returns: An Array of HMCDUpsertableObject.
    /// - Throws: Exception if the data is not available.
    func dataToUpsert() throws -> [HMCDUpsertableObject]
}

public extension HMCDRequestType {
    
    /// Get the associated fetch request.
    ///
    /// - Returns: A NSFetchRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func fetchRequest<Val>() throws -> NSFetchRequest<Val> where Val: NSFetchRequestResult {
        let description = try entityName()
        let cdRequest = NSFetchRequest<Val>(entityName: description)
        cdRequest.predicate = try predicate()
        cdRequest.sortDescriptors = try sortDescriptors()
        return cdRequest
    }
}
