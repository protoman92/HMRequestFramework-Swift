//
//  HMCDManagers.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

extension HMCDManager: HMCDRxManagerType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter obs: An ObserverType instance.
    public func persistChangesToFile<O>(_ obs: O) where O: ObserverType, O.E == Void {
        save(context: privateContext, obs)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveInMemory<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        let context = interfaceObjectContext()
        
        context.performAndWait {
            do {
                try self.saveInMemoryUnsafely(data)
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Override this method to provide default implementation.
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
        let context = interfaceObjectContext()
        
        context.performAndWait {
            do {
                try self.deleteFromMemoryUnsafely(data)
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
    ///   - data: A Sequence of HMCDPureObjectType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the save fails.
    public func saveInMemory<S,PO,O>(_ data: S, _ obs: O) where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO,
        O: ObserverType,
        O.E == Void
    {
        let context = interfaceObjectContext()
        
        context.performAndWait {
            do {
                try saveInMemoryUnsafely(data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

extension HMCDManager: ReactiveCompatible {}

public extension Reactive where Base: HMCDManager {
    
    /// Save changes for a NSManagedObjectContext.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: An Observable instance.
    public func save(context: NSManagedObjectContext) -> Observable<Void> {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<Void>) in
            base.save(context: context, obs)
            return Disposables.create()
        })
    }
    
    /// Save data to interface context.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveInMemory(data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save data to interface context.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return saveInMemory(data.map({$0 as NSManagedObject}))
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to the
    /// interface context.
    ///
    /// - Parameters data: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    public func saveInMemory<S,PO>(_ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveInMemory(data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a lazily produced Sequence of data to the interface context.
    ///
    /// - Parameter data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveInMemory(dataFn, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a lazily produced Sequence of data to the interface context.
    ///
    /// - Parameter data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveInMemory(dataFn, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete data from the interface context.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.deleteFromMemory(data, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete data from file.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return deleteFromMemory(data.map({$0 as NSManagedObject}))
    }
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistAllChangesToFile() -> Observable<Void> {
        let base = self.base
        
        return Observable.concat(
            save(context: base.mainContext),
            save(context: base.privateContext)
        )
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ request: NSFetchRequest<Val>) -> Observable<Val> {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<[Val]>) in
            do {
                let result = try base.blockingFetch(request)
                obs.onNext(result)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
            
            return Disposables.create()
        }).flatMap({Observable.from($0)})
    }
}
