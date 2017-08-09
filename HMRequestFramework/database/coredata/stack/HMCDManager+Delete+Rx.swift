//
//  HMCDManager+Delete.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

public extension HMCDManager {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteUnsafely<NS,S>(_ context: NSManagedObjectContext,
                                     _ data: S) throws where
        NS: NSManagedObject, S: Sequence, S.Iterator.Element == NS
    {
        let data = data.map(eq)
        
        if data.isNotEmpty {
            try blockingRefetch(context, data).forEach(context.delete)
            try saveUnsafely(context)
        }
    }
    
    /// Delete a Sequence of upsertable data from memory by refetching them
    /// using some context.
    ///
    /// This is different from the above operation because the predicate used
    /// here involves primaryKey/primaryValue of each object, not objectID.
    ///
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func deleteUnsafely<U,S>(_ context: NSManagedObjectContext,
                                    _ entityName: String,
                                    _ data: S) throws where
        U: HMCDUpsertableObject, S: Sequence, S.Iterator.Element == U
    {
        let data = try blockingRefetch(context, entityName, data)
        
        if data.isNotEmpty {
            data.forEach(context.delete)
            try saveUnsafely(context)
        }
    }
}

public extension HMCDManager {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the delete fails.
    public func delete<NS,S,O>(_ context: NSManagedObjectContext,
                               _ data: S,
                               _ obs: O) where
        NS: NSManagedObject,
        S: Sequence, S.Iterator.Element == NS,
        O: ObserverType, O.E == Void
    {
        performOnContextThread(context) {
            do {
                try self.deleteUnsafely(context, data)
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
    public func delete<U,S,O>(_ context: NSManagedObjectContext,
                              _ entityName: String,
                              _ data: S,
                              _ obs: O) where
        U: HMCDUpsertableObject,
        S: Sequence, S.Iterator.Element == U,
        O: ObserverType, O.E == Void
    {
        performOnContextThread(context) {
            do {
                try self.deleteUnsafely(context, entityName, data)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
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
