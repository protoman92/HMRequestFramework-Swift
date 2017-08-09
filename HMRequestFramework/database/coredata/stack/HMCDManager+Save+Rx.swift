//
//  HMCDManager+Save.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift

public extension HMCDManager {
    
    /// Save changes in a context. This operation is not thread-safe.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Throws: Exception if the save fails.
    public func saveUnsafely(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    /// Save changes to file. This operation is not thread-safe.
    ///
    /// This method should be the only one that uses the private context to
    /// save to the local DB file. All other operations should use the main
    /// context.
    ///
    /// - Throws: Exception if the save fails.
    public func persistChangesUnsafely() throws {
        try saveUnsafely(privateContext)
    }
}

public extension HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - dataFn: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    public func saveUnsafely<S>(_ context: NSManagedObjectContext,
                                _ data: S) throws where
        // For some reasons, XCode 8 cannot compile if we define a separate
        // generics for S.Iterator.Element. Although this is longer, it works
        // for both XCode 8 and 9.
        S: Sequence,
        S.Iterator.Element: HMCDPureObjectType,
        S.Iterator.Element.CDClass: HMCDObjectBuildableType,
        S.Iterator.Element.CDClass.Builder.PureObject == S.Iterator.Element
    {
        let _ = try data.map({try self.constructUnsafely(context, $0)})
        try saveUnsafely(context)
    }
}

public extension HMCDManager {
    
    /// Save context changes and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - obs: An ObserverType instance.
    public func save<O>(_ context: NSManagedObjectContext, _ obs: O)
        where O: ObserverType, O.E == Void
    {
        performOnContextThread(mainContext, .performAndWait) {
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

public extension HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects, save it to the
    /// database and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of HMCDPureObjectType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the save fails.
    public func save<S,PO,O>(_ context: NSManagedObjectContext,
                             _ data: S,
                             _ obs: O) where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO,
        O: ObserverType,
        O.E == Void
    {
        performOnContextThread(context) {
            do {
                try self.saveUnsafely(context, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
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
        return save(base.disposableObjectContext(), data)
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
