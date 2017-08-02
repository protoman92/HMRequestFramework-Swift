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

extension HMCDManager: HMCDRxManagerType {}
extension HMCDManager: ReactiveCompatible {}

public extension Reactive where Base: HMCDManager {
    
    /// Save changes for a NSManagedObjectContext.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: An Observable instance.
    public func save(_ context: NSManagedObjectContext) -> Observable<Void> {
        return Observable.create({(obs: AnyObserver<Void>) in
            self.base.save(context, obs)
            return Disposables.create()
        })
    }
}

public extension Reactive where Base: HMCDManager {
    
//    /// Save data to memory.
//    ///
//    /// - Parameters:
//    ///   - context: A NSManagedObjectContext instance.
//    ///   - data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func saveInMemory<S>(_ context: NSManagedObjectContext,
//                                _ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element == NSManagedObject
//    {
//        let data = data.map(eq)
//
//        return Observable.create(({(obs: AnyObserver<Void>) in
//            self.base.saveInMemory(context, data, obs)
//            return Disposables.create()
//        }))
//    }
    
//    /// Save data to memory.
//    ///
//    /// - Parameters:
//    ///   - context: A NSManagedObjectContext instance.
//    ///   - data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func saveInMemory<S>(_ context: NSManagedObjectContext,
//                                _ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element: NSManagedObject
//    {
//        return saveInMemory(context, data.map({$0 as NSManagedObject}))
//    }
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func saveInMemory<S,PO>(_ context: NSManagedObjectContext,
                                   _ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.saveInMemory(context, data, obs)
            return Disposables.create()
        }))
    }
}

public extension Reactive where Base: HMCDManager {
    
//    /// Save data to a disposable context.
//    ///
//    /// - Parameter data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element == NSManagedObject
//    {
//        let context = base.disposableObjectContext()
//        print(context)
//        return saveInMemory(context, data)
//    }
//
//    /// Save data to a disposable context.
//    ///
//    /// - Parameter data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element: NSManagedObject
//    {
//        return saveInMemory(data.map({$0 as NSManagedObject}))
//    }
    
    /// Construct a Sequence of CoreData from data objects and save it to the
    /// disposable context.
    ///
    /// - Parameter data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func saveInMemory<S,PO>(_ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return saveInMemory(base.disposableObjectContext(), data)
    }
}

public extension Reactive where Base: HMCDManager {
    
//    /// Delete data from memory.
//    ///
//    /// - Parameters:
//    ///   - context: A NSManagedObjectContext instance.
//    ///   - data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func deleteFromMemory<S>(_ context: NSManagedObjectContext,
//                                    _ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element == NSManagedObject
//    {
//        return Observable.create(({(obs: AnyObserver<Void>) in
//            self.base.deleteFromMemory(context, data, obs)
//            return Disposables.create()
//        }))
//    }
//
//    /// Delete data from memory.
//    ///
//    /// - Parameters:
//    ///   - context: A NSManagedObjectContext instance.
//    ///   - data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func deleteFromMemory<S>(_ context: NSManagedObjectContext,
//                                    _ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element: NSManagedObject
//    {
//        return deleteFromMemory(context, data.map({$0 as NSManagedObject}))
//    }
}

public extension Reactive where Base: HMCDManager {
    
//    /// Delete data from memory.
//    ///
//    /// - Parameters data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element == NSManagedObject
//    {
//        return deleteFromMemory(base.disposableObjectContext(), data)
//    }
//    
//    /// Delete data from memory.
//    ///
//    /// - Parameters data: A Sequence of NSManagedObject.
//    /// - Returns: An Observable instance.
//    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
//        S: Sequence, S.Iterator.Element: NSManagedObject
//    {
//        let context = base.disposableObjectContext()
//        return deleteFromMemory(context, data.map({$0 as NSManagedObject}))
//    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistAllChangesToFile() -> Observable<Void> {
        let mainContext = base.mainContext
        let privateContext = base.privateContext
        
        return Observable
            .concat(save(mainContext), save(privateContext))
            .reduce((), accumulator: {_ in ()})
    }
}

public extension Reactive where Base: HMCDManager {
    
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
