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
    public func saveToFile<O>(_ obs: O) where O: ObserverType, O.E == Void {
        save(privateContext, obs)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    public func saveToFile<S,O>(_ data: S, _ obs: O) where
        S: Sequence,
        S.Iterator.Element == NSManagedObject,
        O: ObserverType,
        O.E == Void
    {
        let data = data.map(eq)
        
        privateContext.performAndWait {
            do {
                if data.isNotEmpty {
                    try self.saveToFileUnsafely(data)
                }
                
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

extension HMCDManager: ReactiveCompatible {}

public extension Reactive where Base: HMCDRxManagerType {
    
    /// Save changes for a NSManagedObjectContext.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: An Observable instance.
    public func save(_ context: NSManagedObjectContext) -> Observable<Void> {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<Void>) in
            base.save(context, obs)
            return Disposables.create()
        })
    }
    
    /// Save changes to the main context.
    ///
    /// - Returns: An Observable instance.
    public func saveMainContext() -> Observable<Void> {
        return save(base.mainObjectContext())
    }
    
    /// Save changes to file.
    ///
    /// - Returns: An Observable instance.
    public func saveToFile() -> Observable<Void> {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveToFile(obs)
            return Disposables.create()
        }))
    }
    
    /// Save data to file.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveToFile<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveToFile(data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save data to file.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveToFile<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return saveToFile(data.map({$0 as NSManagedObject}))
    }
    
    /// Save a lazily produced Sequence of data to file.
    ///
    /// - Parameter data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveToFile<S>(_ dataFn: @escaping () throws -> S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveToFile(dataFn, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a lazily produced Sequence of data to file.
    ///
    /// - Parameter data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveToFile<S>(_ dataFn: @escaping () throws -> S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveToFile(dataFn, obs)
            return Disposables.create()
        }))
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to the
    /// database.
    ///
    /// - Parameters data: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    public func saveToFile<S,PS>(_ data: S) -> Observable<Void> where
        PS: HMCDPureObjectType,
        PS.CDClass: HMCDBuildable,
        PS.CDClass.Builder.Base == PS,
        S: Sequence,
        S.Iterator.Element == PS
    {
        let base = self.base
        
        return Observable.create(({(obs: AnyObserver<Void>) in
            base.saveToFile(data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistAll() -> Observable<Void> {
        return Observable.concat(saveMainContext(), saveToFile())
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ request: NSFetchRequest<Val>) -> Observable<Val>
        where Val: NSFetchRequestResult
    {
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
