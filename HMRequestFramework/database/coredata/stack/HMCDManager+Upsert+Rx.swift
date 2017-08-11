//
//  HMCDManager+Upsert+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift

public extension HMCDManager {
    
    /// Perform an upsert operation for some upsertable data. For items that
    /// do not exist in the DB yet, we simply insert them.
    ///
    /// This method does not attemp to perform any version control - it is
    /// assumed that the data that are passed in do not require such feature.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    ///   - obs: An ObserverType instance.
    func upsert<U,S,O>(_ context: NSManagedObjectContext,
                       _ entityName: String,
                       _ upsertables: S,
                       _ obs: O) where
        U: NSFetchRequestResult,
        U: HMCDIdentifiableType,
        U: HMCDConvertibleType,
        U: HMCDUpdatableType,
        S: Sequence,
        S.Iterator.Element == U,
        O: ObserverType,
        O.E == [HMResult<U>]
    {
        performOnContextThread(mainContext) {
            do {
                let existing = try self.blockingRefetch(context, entityName, upsertables)
                var results: [HMResult<U>] = []
                
                // We need an Array here to keep track of the objects that do
                // not exist in DB yet.
                var nonExisting: [U] = []
                
                for upsertable in upsertables {
                    if let item = existing.first(where: upsertable.identifiable) {
                        let result: HMResult<U>
                        
                        do {
                            try item.update(from: upsertable)
                            
                            result = HMResult<U>.builder()
                                .with(object: upsertable)
                                .build()
                        } catch let e {
                            result = HMResult<U>.builder()
                                .with(object: upsertable)
                                .with(error: e)
                                .build()
                        }
                        
                        results.append(result)
                    } else {
                        nonExisting.append(upsertable)
                    }
                }
                
                // In the conversion step, the NSManagedObject instances are
                // reconstructed and inserted into the specified context. When
                // we call context.save(), they will also be committed to
                // memory.
                results.append(contentsOf: self.convert(context, nonExisting))
                
                try self.saveUnsafely(context)
                obs.onNext(results)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

extension Reactive where Base: HMCDManager {
    
    /// Perform an upsert request on a Sequence of upsertable objects.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Observable instane.
    func upsert<U,S>(_ context: NSManagedObjectContext,
                     _ entityName: String,
                     _ upsertables: S)
        -> Observable<[HMResult<U>]> where
        U: NSFetchRequestResult,
        U: HMCDIdentifiableType,
        U: HMCDConvertibleType,
        U: HMCDUpdatableType,
        S: Sequence,
        S.Iterator.Element == U
    {
        return Observable<[HMResult<U>]>.create({
            self.base.upsert(context, entityName, upsertables, $0)
            return Disposables.create()
        })
    }
    
    /// Perform an upsert request on a Sequence of upsertable objects with a
    /// disposable context.
    ///
    /// - Parameters:
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Observable instane.
    public func upsert<U,S>(_ entityName: String, _ upsertables: S)
        -> Observable<[HMResult<U>]> where
        U: NSFetchRequestResult,
        U: HMCDIdentifiableType,
        U: HMCDConvertibleType,
        U: HMCDUpdatableType,
        S: Sequence,
        S.Iterator.Element == U
    {
        return upsert(base.disposableObjectContext(), entityName, upsertables)
    }
}
