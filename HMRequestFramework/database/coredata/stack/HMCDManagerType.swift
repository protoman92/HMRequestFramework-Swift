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
    public func predicateForUpsertableFetch<S>(_ data: S) -> NSPredicate where
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
    public func predicateForUpsertableFetch<S>(_ data: S) -> NSPredicate where
        S: Sequence, S.Iterator.Element: HMCDUpsertableType
    {
        return predicateForUpsertableFetch(data.map({$0 as HMCDUpsertableType}))
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
    public func blockingFetch<Val>(_ request: NSFetchRequest<Val>,
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
    public func blockingFetch<Val>(_ context: NSManagedObjectContext,
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
    public func blockingFetch<Val>(_ context: NSManagedObjectContext,
                                   _ request: NSFetchRequest<Val>,
                                   _ cls: Val.Type) throws -> [Val] {
        return try blockingFetch(context, request)
    }
    
    /// Fetch data from a context using a request and a specified PureObject class.
    /// This operation blocks.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A PO class type.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails
    public func blockingFetch<PO>(_ context: NSManagedObjectContext,
                                  _ request: NSFetchRequest<PO.CDClass>,
                                  _ cls: PO.Type) throws -> [PO.CDClass]
        where PO: HMCDPureObjectType
    {
        return try blockingFetch(context, request, cls.CDClass.self)
    }
    
    /// Refetch some NSManagedObject from DB.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    public func blockingRefetch<NS,S>(_ context: NSManagedObjectContext,
                                      _ data: S) throws
        -> [NSManagedObject] where
        NS: NSManagedObject,
        S: Sequence,
        S.Iterator.Element == NS
    {
        return try data.map({$0.objectID}).flatMap(context.existingObject)
    }
    
    /// Fetch objects from DB whose primary key values correspond to those
    /// supplied by the specified upsertable objects.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - upsertables: A Sequence of HMCDUpsertableObject.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    public func blockingRefetch<U,S>(_ context: NSManagedObjectContext,
                                     _ entityName: String,
                                     _ upsertables: S) throws -> [U] where
        U: HMCDUpsertableObject,
        S: Sequence,
        S.Iterator.Element == U
    {
        let data = upsertables.map({$0})
        
        if data.isNotEmpty {
            let predicate = predicateForUpsertableFetch(data)
            let request: NSFetchRequest<U> = NSFetchRequest(entityName: entityName)
            request.predicate = predicate
            return try blockingFetch(context, request)
        } else {
            return []
        }
    }
}

public extension HMCDManagerType {
    
    /// Save changes in a context. This operation is not thread-safe.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Throws: Exception if the save fails.
    public func saveUnsafely(_ context: NSManagedObjectContext) throws {
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
    public func saveUnsafely<S>(_ context: NSManagedObjectContext,
                                _ data: S) throws where
        // For some reasons, XCode 8 cannot compile if we define a separate
        // generics for S.Iterator.Element. Although this is longer, it works
        // for both XCode 8 and 9.
        S: Sequence,
        S.Iterator.Element: HMCDPureObjectType,
        S.Iterator.Element.CDClass: HMCDObjectBuildableType,
        S.Iterator.Element.CDClass.Builder.PureObject == S.Iterator.Element
    {
        let _ = try data.map({try self.constructUnsafely(context, $0)})
        try saveUnsafely(context)
    }
}

public extension HMCDManagerType {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteUnsafely<NS,S>(_ context: NSManagedObjectContext,
                                     _ data: S) throws where
        NS: NSManagedObject, S: Sequence, S.Iterator.Element == NS
    {
        let data = data.map(eq)
        
        if data.isNotEmpty {
            try blockingRefetch(context, data).forEach(context.delete)
            try saveUnsafely(context)
        }
    }
    
    /// Delete a Sequence of upsertable data from memory by refetching them
    /// using some context.
    ///
    /// This is different from the above operation because the predicate used
    /// here involves primaryKey/primaryValue of each object, not objectID.
    ///
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteUnsafely<U,S>(_ context: NSManagedObjectContext,
                                    _ entityName: String,
                                    _ data: S) throws where
        U: HMCDUpsertableObject, S: Sequence, S.Iterator.Element == U
    {
        let data = try blockingRefetch(context, entityName, data)
        
        if data.isNotEmpty {
            data.forEach(context.delete)
            try saveUnsafely(context)
        }
    }
}
