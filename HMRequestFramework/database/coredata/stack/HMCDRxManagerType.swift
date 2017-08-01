//
//  HMCDRxManagerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol should be able to handle rx-specific
/// CoreData operations.
public protocol HMCDRxManagerType: HMCDManagerType {}

public extension HMCDRxManagerType {
    
    /// Save context changes and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - obs: An ObserverType instance.
    public func save<O>(context: NSManagedObjectContext, _ obs: O)
        where O: ObserverType, O.E == Void
    {
        context.performAndWait {
            do {
                try self.saveUnsafely(context: context)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDRxManagerType {
    
    /// Save data to memory and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ context: NSManagedObjectContext,
                                  _ data: S,
                                  _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        context.performAndWait {
            do {
                try self.saveInMemoryUnsafely(context, data)
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Construct a Sequence of CoreData from data objects, save it to the
    /// database and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of HMCDPureObjectType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the save fails.
    public func saveInMemory<S,PO,O>(_ context: NSManagedObjectContext,
                                     _ data: S,
                                     _ obs: O) where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO,
        O: ObserverType,
        O.E == Void
    {
        context.performAndWait {
            do {
                try saveInMemoryUnsafely(context, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Save data and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ context: NSManagedObjectContext,
                                  _ data: S,
                                  _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        saveInMemory(context, data.map({$0 as NSManagedObject}), obs)
    }
    
    /// Save a lazily produced Sequence of data and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ context: NSManagedObjectContext,
                                  _ dataFn: () throws -> S,
                                  _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveInMemory(context, data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Save a lazily produced Sequence of data and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ context: NSManagedObjectContext,
                                  _ dataFn: () throws -> S,
                                  _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveInMemory(context, data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
}

public extension HMCDRxManagerType {
    
    /// Delete data from memory and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func deleteFromMemory<S,O>(_ context: NSManagedObjectContext,
                                      _ data: S,
                                      _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        context.performAndWait {
            do {
                try self.deleteFromMemoryUnsafely(context, data)
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Delete data and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func deleteFromMemory<S,O>(_ context: NSManagedObjectContext,
                                      _ data: S,
                                      _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        deleteFromMemory(context, data.map({$0 as NSManagedObject}), obs)
    }
}
