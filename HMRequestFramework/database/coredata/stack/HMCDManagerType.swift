//
//  HMCDManagerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol must be able to handle CoreData-based
/// operations.
public protocol HMCDManagerType: HMCDObjectConstructorType {
    
    /// Construct a HMCDManagerType.
    ///
    /// - Parameter constructor: A HMCDConstructorType instance.
    /// - Throws: Exception if construction fails.
    init(constructor: HMCDConstructorType) throws
    
    /// Save changes to file. This operation is not thread-safe.
    ///
    /// This method should be the only one that uses the private context to
    /// save to the local DB file. All other operations should use the main
    /// context.
    ///
    /// - Throws: Exception if the save fails.
    func persistChangesToFileUnsafely() throws
    
    /// Fetch data using a request. This operation blocks.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    func blockingFetch<Val>(_ request: NSFetchRequest<Val>) throws -> [Val]
}

public extension HMCDManagerType {
    
    /// Get the predicate to search for records related to a Sequence of
    /// upsertables. This predicate will be used to distinguish between
    /// existing and new data.
    ///
    /// - Parameter data: A Sequence of HMCDUpsertableType.
    /// - Returns: A NSPredicate instance.
    func predicateForUpsertableFetch<S>(_ data: S) -> NSPredicate where
        S: Sequence, S.Iterator.Element == HMCDUpsertableType
    {
        return NSCompoundPredicate(orPredicateWithSubpredicates: data
            .map({($0.primaryKey(), $0.primaryValue())})
            .map({NSPredicate(format: "%K == %@", $0.0, $0.1)}))
    }
    
    /// Get the predicate to search for records related to a Sequence of
    /// upsertables. This predicate will be used to distinguish between
    /// existing and new data.
    ///
    /// - Parameter data: A Sequence of HMCDUpsertableType.
    /// - Returns: A NSPredicate instance.
    func predicateForUpsertableFetch<S>(_ data: S) -> NSPredicate where
        S: Sequence, S.Iterator.Element: HMCDUpsertableType
    {
        return predicateForUpsertableFetch(data.map({$0 as HMCDUpsertableType}))
    }
    
    /// Get the predicate to search for records based on ObjectID.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: A NSPredicate instance.
    func predicateForObjectIDFetch<S>(_ data: S) -> NSPredicate where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return NSCompoundPredicate(orPredicateWithSubpredicates: data
            .map({$0.objectID})
            .map({NSPredicate(format: "objectID == %@", $0)}))
    }
}

public extension HMCDManagerType {
    
    /// Fetch data using a request and a specified Val class. This operation blocks.
    ///
    /// - Parameters:
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A Val class type.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    func blockingFetch<Val>(_ request: NSFetchRequest<Val>,
                            _ cls: Val.Type) throws -> [Val] {
        return try blockingFetch(request)
    }
    
    /// Fetch data from a context using a request. This operation blocks.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    func blockingFetch<Val>(_ context: NSManagedObjectContext,
                            _ request: NSFetchRequest<Val>) throws
        -> [Val]
    {
        return try context.fetch(request)
    }
    
    /// Fetch data from a context using a request and a specified Val class.
    /// This operation blocks.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A Val class type.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails
    func blockingFetch<Val>(_ context: NSManagedObjectContext,
                            _ request: NSFetchRequest<Val>,
                            _ cls: Val.Type) throws -> [Val] {
        return try blockingFetch(context, request)
    }
    
    /// Re-fetch some data based on ObjectID and insert them into some disposable
    /// context. This is useful for save/delete operations whereby we are not
    /// certain what contexts the data are inserted in.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Array of Element.
    /// - Throws: Exception if the fetch fails.
    func blockingRefetch<S>(_ context: NSManagedObjectContext,
                            _ entityName: String,
                            _ data: S) throws
        -> [S.Iterator.Element] where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        let predicate = predicateForObjectIDFetch(data)
        let request: NSFetchRequest<S.Iterator.Element> = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        return try context.fetch(request)
    }
}

public extension HMCDManagerType {
    
    /// Save changes in a context. This operation is not thread-safe.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Throws: Exception if the save fails.
    func saveUnsafely(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

public extension HMCDManagerType {
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    func saveInMemoryUnsafely<S,PO>(_ context: NSManagedObjectContext,
                                    _ data: S) throws where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        let _ = try data.map({try self.construct(context, $0)})
        try saveUnsafely(context)
    }
}

public extension HMCDManagerType {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    func deleteFromMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                     _ entityName: String,
                                     _ data: S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        let data = data.map(eq)
        
        if data.isNotEmpty {
            let refetched = try blockingRefetch(context, entityName, data)
            refetched.forEach(context.delete)
            try saveUnsafely(context)
        }
    }
}
