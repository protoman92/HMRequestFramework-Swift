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
                try saveInMemoryUnsafely(context, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}
