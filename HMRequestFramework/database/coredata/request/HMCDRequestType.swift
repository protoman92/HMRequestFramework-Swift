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
    
    /// Get the data to be saved. Only used with save operations.
    ///
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the data is not available.
    func dataToSave() throws -> [NSManagedObject]
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
