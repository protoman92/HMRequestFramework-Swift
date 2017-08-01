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
    func persistChangesToFile<O>(_ obs: O) where O: ObserverType, O.E == Void
    
    /// Save data to the interface context and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    func saveInMemory<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    
    /// Delete data from the interface context and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    func deleteFromMemory<S,O>(_ data: S, _ obs: O) where
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
    
    /// Save data and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        saveInMemory(data.map({$0 as NSManagedObject}), obs)
    }
    
    /// Save a lazily produced Sequence of data and observe the process.
    ///
    /// - Parameters:
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ dataFn: () throws -> S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveInMemory(data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Save a lazily produced Sequence of data and observe the process.
    ///
    /// - Parameters:
    ///   - dataFn: A function that produces data.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ dataFn: () throws -> S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element: NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        do {
            let data = try dataFn()
            saveInMemory(data, obs)
        } catch let e {
            obs.onError(e)
        }
    }
    
    /// Delete data and observe the process.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func deleteFromMemory<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        deleteFromMemory(data.map({$0 as NSManagedObject}), obs)
    }
}
