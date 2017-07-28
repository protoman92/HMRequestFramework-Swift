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
    
    /// Get the main-queue object context.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    func mainObjectContext() -> NSManagedObjectContext
    
    /// Save changes to file. This operation is not thread-safe.
    ///
    /// - Throws: Exception if the save fails.
    func saveToFileUnsafely() throws
    
    /// Save a Sequence of data to file. This operation is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    func saveToFileUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    
    /// Fetch data using a request. This operation blocks.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Array of NSManagedObject.
    /// - Throws: Exception if the fetch fails.
    func blockingFetch<Val>(_ request: NSFetchRequest<Val>) throws -> [Val]
        where Val: NSFetchRequestResult
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
    
    /// Save a Sequence of data to file. This operation is not thread-safe.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the save fails.
    public func saveToFileUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return try saveToFileUnsafely(data.map({$0 as NSManagedObject}))
    }
    
    /// Save a lazily produced Sequence of data to file. This operation is not
    /// thread-safe.
    ///
    /// - Parameter dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveToFileUnsafely<S>(_ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        try saveToFileUnsafely(dataFn())
    }
    
    /// Save a lazily produced Sequence of data to file. This operation is not
    /// thread-safe.
    ///
    /// - Parameter dataFn: A function that produces data.
    /// - Throws: Exception if the save fails.
    public func saveToFileUnsafely<S>(_ dataFn: () throws -> S) throws where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        try saveToFileUnsafely(dataFn())
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to
    /// the database unsafely.
    ///
    /// - Parameter data: A Sequence of HMCDParsableType.
    /// - Throws: Exception if the save fails.
    public func saveToFileUnsafely<S,PS>(_ data: S) throws where
        PS: HMCDParsableType,
        PS.CDClass: HMCDBuildable,
        PS.CDClass.Builder.Base == PS,
        S: Sequence,
        S.Iterator.Element == PS
    {
        let data = try data.map({try self.construct($0)})
        try saveToFileUnsafely(data)
    }
    
    /// Save changes in the main object context.
    ///
    /// - Throws: Exception if the save fails.
    public func saveMainContextUnsafely() throws {
        try saveUnsafely(mainObjectContext())
    }
    
    /// Get the edit object context. This context should be created dynamically
    /// to provide disposable scratch pads.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    public func editObjectContext() -> NSManagedObjectContext {
        let mainContext = mainObjectContext()
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        return context
    }
}
