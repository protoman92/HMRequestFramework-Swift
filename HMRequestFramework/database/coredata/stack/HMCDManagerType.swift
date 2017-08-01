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
    
    /// Save a Sequence of data to the interface context, without persisting to
    /// DB. This operation is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    func saveInMemoryUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    
    /// Delete a Sequence of data from the interface context, without persisting
    /// to DB. This operation is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    func deleteFromMemoryUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    
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
    
    /// Save a Sequence of data to file. This operation is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return try saveInMemoryUnsafely(data.map({$0 as NSManagedObject}))
    }
    
    /// Save a lazily produced Sequence of data to the interface context,
    /// without persisting to DB. This operation is not thread-safe.
    ///
    /// - Parameter dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        try saveInMemoryUnsafely(dataFn())
    }
    
    /// Save a lazily produced Sequence of data to the interface context. This
    /// operation is not thread-safe.
    ///
    /// - Parameter dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S>(_ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        try saveInMemoryUnsafely(dataFn())
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to
    /// the interface context.
    ///
    /// - Parameter data: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    public func saveInMemoryUnsafely<S,PO>(_ data: S) throws where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        let data = try data.map({try self.construct($0)})
        try saveInMemoryUnsafely(data)
    }
    
    /// Delete a Sequence of data from the interface context. This operation
    /// is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteFromMemoryUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return try deleteFromMemoryUnsafely(data.map({$0 as NSManagedObject}))
    }
}
