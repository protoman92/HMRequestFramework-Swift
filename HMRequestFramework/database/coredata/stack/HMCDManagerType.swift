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
    
    /// Save changes in a context. This operation is not thread-safe.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Throws: Exception if the save fails.
    public func saveUnsafely(context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

public extension HMCDManagerType {
    
    /// Save a Sequence of data to memory, without persisting to DB. This operation
    /// is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                        _ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let data = data.map(eq)
        
        if data.isNotEmpty {
            data.forEach(context.insert)
            try saveUnsafely(context: context)
        }
    }

    /// Save a Sequence of data to memory. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                        _ data: S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return try saveInMemoryUnsafely(context, data.map({$0 as NSManagedObject}))
    }
    
    /// Save a lazily produced Sequence of data to memory, without persisting to
    /// DB. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                        _ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        try saveInMemoryUnsafely(context, dataFn())
    }
    
    /// Save a lazily produced Sequence of data to memory. This operation is
    /// not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                        _ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        try saveInMemoryUnsafely(context, dataFn())
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S,PO>(_ context: NSManagedObjectContext,
                                           _ data: S) throws where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        let cdData = try data.map({try self.construct(context, $0)})
        try saveInMemoryUnsafely(context, cdData)
    }
}

public extension HMCDManagerType {
    
    /// Delete a Sequence of data from memory, without persisting to DB. This
    /// operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteFromMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                            _ data: S) throws where
        S: Sequence, S.Element == NSManagedObject
    {
        let data = data.map(eq)
        
        if data.isNotEmpty {
            data.forEach(context.delete)
            try saveUnsafely(context: context)
        }
    }
    
    /// Delete a Sequence of data from memory. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteFromMemoryUnsafely<S>(_ context: NSManagedObjectContext,
                                            _ data: S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return try deleteFromMemoryUnsafely(context, data.map({$0 as NSManagedObject}))
    }
}
