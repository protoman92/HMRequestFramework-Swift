//
//  HMCDManager+Delete+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

public extension HMCDManager {
    
    /// Delete items in DB using some fetch request. This operation is not
    /// thread-safe.
    ///
    /// Beware that this is only available for SQLite stores.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - request: A NSFetchRequest instance.
    /// - Returns: A NSBatchDeleteResult instance.
    /// - Throws: Exception if the operation fails.
    func deleteUnsafely(_ context: Context,
                        _ request: NSFetchRequest<NSFetchRequestResult>) throws
        -> NSBatchDeleteResult
    {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        if let result = try context.execute(deleteRequest) as? NSBatchDeleteResult {
            return result
        } else {
            throw Exception("Invalid batch delete result")
        }
    }
}

public extension HMCDManager {
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context. This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    func deleteUnsafely<NS,S>(_ context: Context, _ data: S) throws where
        NS: NSManagedObject, S: Sequence, S.Element == NS
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
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - ids: A Sequence of NSManagedObject.
    /// - Throws: Exception if the delete fails.
    func deleteIdentifiablesUnsafely<S>(_ context: Context,
                                        _ entityName: String,
                                        _ ids: S) throws where
        S: Sequence, S.Element == HMCDIdentifiableType
    {
        let data = try blockingFetchIdentifiables(context, entityName, ids)
        
        if data.isNotEmpty {
            data.forEach(context.delete)
            try saveUnsafely(context)
        }
    }
}

public extension HMCDManager {
    
    /// Delete items in DB using some fetch request and observe the result.
    /// Beware that this is only available for SQLite stores.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - request: A NSFetchRequest instance.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func delete<O>(_ context: Context,
                   _ request: NSFetchRequest<NSFetchRequestResult>,
                   _ opMode: HMCDOperationMode,
                   _ obs: O) -> Disposable where
        O: ObserverType, O.E == NSBatchDeleteResult
    {
        Preconditions.checkNotRunningOnMainThread(request)
        
        performOperation(opMode, {
            do {
                let result = try self.deleteUnsafely(context, request)
                obs.onNext(result)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    public func delete<NS,S,O>(_ context: Context,
                               _ data: S,
                               _ opMode: HMCDOperationMode,
                               _ obs: O) -> Disposable where
        NS: NSManagedObject,
        S: Sequence, S.Element == NS,
        O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(data)
        
        performOperation(opMode, {
            do {
                try self.deleteUnsafely(context, data)
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - ids: A Sequence of HMCDIdentifiableType.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    public func deleteIdentifiables<S,O>(_ context: Context,
                                         _ entityName: String,
                                         _ ids: S,
                                         _ opMode: HMCDOperationMode,
                                         _ obs: O) -> Disposable where
        S: Sequence,
        S.Element == HMCDIdentifiableType,
        O: ObserverType,
        O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(entityName)
        
        performOperation(opMode, {
            do {
                try self.deleteIdentifiablesUnsafely(context, entityName, ids)
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
}

public extension Reactive where Base == HMCDManager {
    
    /// Delete items in DB using some fetch request. Beware that this is only
    /// available for SQLite stores.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - request: A NSFetchRequest instance.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Return: An Observable instance.
    public func delete(_ context: HMCDManager.Context,
                       _ request: NSFetchRequest<NSFetchRequestResult>,
                       _ opMode: HMCDOperationMode = .queued)
        -> Observable<NSBatchDeleteResult>
    {
        return Observable.create({self.base.delete(context, request, opMode, $0)})
    }
    
    /// Delete a Sequence of data from memory by refetching them using some
    /// context.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - data: A Sequence of NSManagedObject.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Throws: Exception if the delete fails.
    public func delete<S>(_ context: HMCDManager.Context,
                          _ data: S,
                          _ opMode: HMCDOperationMode = .queued)
        -> Observable<Void> where
        S: Sequence, S.Element: NSManagedObject
    {
        return Observable.create({self.base.delete(context, data, opMode, $0)})
    }
}

public extension Reactive where Base == HMCDManager {
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - ids: A Sequence of HMCDIdentifiableType.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Throws: Exception if the delete fails.
    public func deleteIdentifiables<S>(_ context: HMCDManager.Context,
                                       _ entityName: String,
                                       _ ids: S,
                                       _ opMode: HMCDOperationMode = .queued)
        -> Observable<Void> where
        S: Sequence, S.Element == HMCDIdentifiableType
    {
        return Observable.create({
            self.base.deleteIdentifiables(context, entityName, ids, opMode, $0)
        })
    }
    
    /// Delete a Sequence of identifiable data from memory by refetching them
    /// using some context.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - ids: A Sequence of HMCDIdentifiableType.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Throws: Exception if the delete fails.
    public func deleteIdentifiables<U,S>(_ context: HMCDManager.Context,
                                         _ entityName: String,
                                         _ ids: S,
                                         _ opMode: HMCDOperationMode = .queued)
        -> Observable<Void> where
        U: HMCDIdentifiableType,
        S: Sequence,
        S.Element == U
    {
        let ids = ids.map({$0 as HMCDIdentifiableType})
        return deleteIdentifiables(context, entityName, ids, opMode)
    }
}
