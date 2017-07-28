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
public protocol HMCDRxManagerType: HMCDManagerType {
    
    /// Save changes to file and observe the process. This should save changes
    /// in the private context.
    ///
    /// - Parameter obs: An ObserverType instance.
    func saveToFile<O>(_ obs: O) where O: ObserverType, O.E == Void
    
    /// Save data to file and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    func saveToFile<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
}

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
    
    /// Save data to file and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveToFile<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        return saveToFile(data.map({$0 as NSManagedObject}), obs)
    }
    
    /// Save a lazily produced Sequence of data to file and observe the process.
    ///
    /// - Parameters:
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveToFile<S,O>(_ dataFn: () throws -> S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveToFile(data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Save a lazily produced Sequence of data to file and observe the process.
    ///
    /// - Parameters:
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveToFile<S,O>(_ dataFn: () throws -> S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveToFile(data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Construct a Sequence of CoreData from data objects, save it to the
    /// database and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of HMCDPureObjectType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the save fails.
    public func saveToFile<S,PO,O>(_ data: S, _ obs: O) where
        O: ObserverType,
        O.E == Void,
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDBuildable,
        PO.CDClass.Builder.Base == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        do {
            try saveToFileUnsafely(data)
            obs.onNext()
            obs.onCompleted()
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Save changes in the main context.
    ///
    /// - Parameter obs: An ObserverType instance.
    public func saveMainContext<O>(_ obs: O) where O: ObserverType, O.E == Void {
        save(mainObjectContext(), obs)
    }
}
