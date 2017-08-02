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
    
    /// Get the context to perform a save operation. The context should contain
    /// changes to be modified from memory.
    ///
    /// It is crucial that this context is a newly created disposable one (to
    /// avoid shared state in the main context).
    ///
    /// - Returns: A NSManagedObjectContext instance.
    /// - Throws: Exception if the context is not available.
    func contextToSave() throws -> NSManagedObjectContext
    
    /// Get the data to be deleted. Only used for delete operations.
    ///
    /// The reason why we can specify exactly the data to delete (instead of
    /// passing a context with changes to be saved, as is the case for save
    /// and upsert) is that we can actually create a disposable context ourselves,
    /// populate it with data pulled from the DB using objectIDs and call said
    /// context's delete(_:) method without it throwing an Error.
    ///
    /// For save/upsert, it's not possible to do this since most likely the
    /// data are not yet in the DB, and we cannot pass objects between contexts.
    /// Therefore, we can neither query the DB nor transfer the data to our
    /// own disposable context.
    ///
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the data is not available.
    func dataToDelete() throws -> [NSManagedObject]
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
