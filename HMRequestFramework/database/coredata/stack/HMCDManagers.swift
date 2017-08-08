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
extension HMCDManager: HMCDRxObjectConstructorType {}
extension HMCDManager: ReactiveCompatible {}

public extension Reactive where Base: HMCDManager {
    
    /// Construct CoreData objects from multiple pure objects.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - pureObjs: A Sequence of PO.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the construction fails.
    public func construct<PO,S>(_ context: NSManagedObjectContext, _ pureObjs: S)
        -> Observable<[PO.CDClass]> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Iterator.Element == PO
    {
        return Observable.create({(obs: AnyObserver<[PO.CDClass]>) in
            self.base.construct(context, pureObjs, obs)
            return Disposables.create()
        })
    }
}

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
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func save<S,PO>(_ context: NSManagedObjectContext,
                           _ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.save(context, data, obs)
            return Disposables.create()
        }))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects and save it to the
    /// disposable context.
    ///
    /// - Parameter data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func save<S,PO>(_ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return save(base.defaultCreateContext(), data)
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func delete<NS,S>(_ context: NSManagedObjectContext, _ data: S)
        -> Observable<Void> where
        NS: NSManagedObject, S: Sequence, S.Iterator.Element == NS
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.delete(context, data, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete a Sequence of data from memory by refetching them using a
    /// disposable context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func delete<NS,S>(_ data: S) -> Observable<Void> where
        NS: NSManagedObject, S: Sequence, S.Iterator.Element == NS
    {
        return delete(base.defaultDeleteContext(), data)
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Delete a Sequence of upsertable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of HMCDUpsertableObject.
    /// - Throws: Exception if the delete fails.
    public func delete<U,S>(_ context: NSManagedObjectContext,
                            _ entityName: String,
                            _ data: S) -> Observable<Void> where
        U: HMCDUpsertableObject, S: Sequence, S.Iterator.Element == U
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.delete(context, entityName, data, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete a Sequence of upsertable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of HMCDUpsertableObject.
    /// - Returns: An Observable instance.
    public func delete<U,S>(_ entityName: String, _ data: S)
        -> Observable<Void> where
        U: HMCDUpsertableObject, S: Sequence, S.Iterator.Element == U
    {
        return delete(base.defaultDeleteContext(), entityName, data)
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistLocally() -> Observable<Void> {
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
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ context: NSManagedObjectContext,
                           _ request: NSFetchRequest<Val>) -> Observable<[Val]> {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<[Val]>) in
            do {
                let result = try base.blockingFetch(context, request)
                obs.onNext(result)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
            
            return Disposables.create()
        })
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A Val class type.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ context: NSManagedObjectContext,
                           _ request: NSFetchRequest<Val>,
                           _ cls: Val.Type) -> Observable<[Val]> {
        return fetch(context, request)
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A PO class type.
    /// - Returns: An Observable instance.
    public func fetch<PO>(_ context: NSManagedObjectContext,
                          _ request: NSFetchRequest<PO.CDClass>,
                          _ cls: PO.Type) -> Observable<[PO.CDClass]>
        where PO: HMCDPureObjectType
    {
        return fetch(context, request, cls.CDClass.self)
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameters request: A NSFetchRequest instance.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ request: NSFetchRequest<Val>) -> Observable<[Val]> {
        return fetch(base.defaultFetchContext(), request)
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameters:
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A Val class type.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ request: NSFetchRequest<Val>,
                           _ cls: Val.Type) -> Observable<[Val]> {
        return fetch(request)
    }
    
    /// Get data for a fetch request.
    ///
    /// - Parameters:
    ///   - request: A NSFetchRequest instance.
    ///   - cls: A PO class type.
    /// - Returns: An Observable instance.
    public func fetch<PO>(_ request: NSFetchRequest<PO.CDClass>,
                          _ cls: PO.Type) -> Observable<[PO.CDClass]>
        where PO: HMCDPureObjectType
    {
        return fetch(request, cls.CDClass.self)
    }
    
    /// Perform a refetch request for a Sequence of upsertable objects.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - upsertables: A Sequence of HMCDUpsertableObject.
    /// - Returns: An Observable instance.
    public func refetch<U,S>(_ context: NSManagedObjectContext,
                             _ entityName: String,
                             _ upsertables: S)
        -> Observable<[U]> where
        U: HMCDUpsertableObject,
        S: Sequence,
        S.Iterator.Element == U
    {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<[U]>) in
            do {
                let result = try base.blockingRefetch(context, entityName, upsertables)
                obs.onNext(result)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
            
            return Disposables.create()
        })
    }
    
    /// Perform a refetch request for a Sequence of upsertable objects, using
    /// the default fetch context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - upsertables: A Sequence of HMCDUpsertableObject.
    /// - Returns: An Observable instance.
    public func refetch<U,S>(_ entityName: String, _ upsertables: S)
        -> Observable<[U]> where
        U: HMCDUpsertableObject,
        S: Sequence,
        S.Iterator.Element == U
    {
        return refetch(base.defaultFetchContext(), entityName, upsertables)
    }
}
