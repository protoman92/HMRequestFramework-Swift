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
    public func save<O>(_ context: NSManagedObjectContext, _ obs: O)
        where O: ObserverType, O.E == Void
    {
        context.performAndWait {
            do {
                try self.saveUnsafely(context)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDRxManagerType {
    
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
                try self.saveInMemoryUnsafely(context, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDRxManagerType {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the delete fails.
    public func deleteFromMemory<NS,S,O>(_ context: NSManagedObjectContext,
                                         _ data: S,
                                         _ obs: O) where
        NS: NSManagedObject,
        S: Sequence, S.Iterator.Element == NS,
        O: ObserverType, O.E == Void
    {
        context.performAndWait {
            do {
                try self.deleteFromMemoryUnsafely(context, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Delete a Sequence of upsertable data from memory by refetching them
    /// using some context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of HMCDUpsertableObject.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the delete fails.
    public func deleteFromMemory<U,S,O>(_ context: NSManagedObjectContext,
                                        _ entityName: String,
                                        _ data: S,
                                        _ obs: O) where
        U: HMCDUpsertableObject,
        S: Sequence, S.Iterator.Element == U,
        O: ObserverType, O.E == Void
    {
        context.performAndWait {
            do {
                try self.deleteFromMemoryUnsafely(context, entityName, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}
