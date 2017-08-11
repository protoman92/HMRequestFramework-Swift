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
    func deleteUnsafely<NS,S>(_ context: NSManagedObjectContext,
                              _ data: S) throws where
        NS: NSManagedObject, S: Sequence, S.Iterator.Element == NS
    {
        let data = data.map({$0})
        
        if data.isNotEmpty {
            try blockingRefetch(context, data).forEach(context.delete)
            try saveUnsafely(context)
        }
    }
    
    /// Delete a Sequence of identifiable data from memory by refetching them
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
    ///   - identifiables: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    func deleteUnsafely<S>(_ context: NSManagedObjectContext,
                           _ entityName: String,
                           _ identifiables: S) throws where
        S: Sequence, S.Iterator.Element == HMCDIdentifiableType
    {
        let data = try blockingRefetch(context, entityName, identifiables)
        
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
    ///   - data: A Sequence of NSManagedObject.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the delete fails.
    public func delete<NS,S,O>(_ data: S, _ obs: O) where
        NS: NSManagedObject,
        S: Sequence, S.Iterator.Element == NS,
        O: ObserverType, O.E == Void
    {
        let context = disposableObjectContext()
        
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
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of HMCDIdentifiableType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the delete fails.
    public func delete<S,O>(_ entityName: String,
                            _ identifiables: S,
                            _ obs: O) where
        S: Sequence, S.Iterator.Element == HMCDIdentifiableType,
        O: ObserverType, O.E == Void
    {
        let context = disposableObjectContext()
        
        performOnContextThread(context) {
            do {
                try self.deleteUnsafely(context, entityName, identifiables)
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
    ///   - entityName: A String value representing the entity's name.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    public func delete<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.delete(data, obs)
            return Disposables.create()
        }))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of HMCDIdentifiableType.
    /// - Throws: Exception if the delete fails.
    public func delete<S>(_ entityName: String, _ identifiables: S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element == HMCDIdentifiableType
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.delete(entityName, identifiables, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of HMCDIdentifiableType.
    /// - Throws: Exception if the delete fails.
    public func delete<U,S>(_ entityName: String, _ identifiables: S)
        -> Observable<Void> where
        U: HMCDIdentifiableType,
        S: Sequence,
        S.Iterator.Element == U
    {
        return delete(entityName, identifiables.map({$0 as HMCDIdentifiableType}))
    }
}
