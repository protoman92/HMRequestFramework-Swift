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
    /// - Throws: Exception if the fetch fails.
    public func blockingFetch<Val>(_ context: NSManagedObjectContext,
                                   _ request: NSFetchRequest<Val>,
                                   _ cls: Val.Type) throws -> [Val] {
        return try blockingFetch(context, request)
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
    public func saveInMemoryUnsafely<S,PO>(_ context: NSManagedObjectContext,
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
