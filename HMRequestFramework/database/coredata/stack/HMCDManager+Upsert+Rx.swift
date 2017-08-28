//
//  HMCDManager+Upsert+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift

// Private extension utility here.
fileprivate extension NSManagedObject {
    
    /// Update inner properties using a HMCDKeyValueUpdatableType.
    ///
    /// - Parameter obj: A HMCDKeyValueRepresentableType instance.
    fileprivate func update(from obj: HMCDKeyValueRepresentableType) {
        let dict = obj.updateDictionary()
        
        for (key, value) in dict {
            setValue(value, forKey: key)
        }
    }
}

public extension HMCDManager {
    
    /// Update upsertables and get results, including those from new object
    /// insertions.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the conversion fails.
    func convert<S>(_ context: Context,
                    _ entityName: String,
                    _ upsertables: S) throws -> [HMCDResult] where
        S: Sequence, S.Iterator.Element == HMCDUpsertableType
    {
        let ids = upsertables.map({$0 as HMCDIdentifiableType})
        let existing = try blockingFetchIdentifiables(context, entityName, ids)
        var results: [HMCDResult] = []
        
        // We need an Array here to keep track of the objects that do not exist
        // in DB yet.
        var nonExisting: [HMCDObjectConvertibleType] = []
        
        for upsertable in upsertables {
            if let item = existing.first(where: upsertable.identifiable) {
                item.update(from: upsertable)
                results.append(HMCDResult.just(upsertable))
            } else {
                nonExisting.append(upsertable)
            }
        }
        
        // In the conversion step, the NSManagedObject instances are
        // reconstructed and inserted into the specified context. When
        // we call context.save(), they will also be committed to
        // memory.
        results.append(contentsOf: self.convert(context, nonExisting))
        
        return results
    }
    
    /// Update upsertables and get results, including those from new object
    /// insertions.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the conversion fails.
    func convert<U,S>(_ context: Context,
                      _ entityName: String,
                      _ upsertables: S) throws -> [HMCDResult] where
        U: HMCDUpsertableType,
        S: Sequence, S.Iterator.Element == U
    {
        let upsertables = upsertables.map({$0 as HMCDUpsertableType})
        return try self.convert(context, entityName, upsertables)
    }
    
    /// Perform an upsert operation for some upsertable data. For items that
    /// do not exist in the DB yet, we simply insert them.
    ///
    /// This method does not attemp to perform any version control - it is
    /// assumed that the data that are passed in do not require such feature.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    ///   - obs: An ObserverType instance.
    func upsert<S,O>(_ context: Context,
                     _ entityName: String,
                     _ upsertables: S,
                     _ obs: O) where
        S: Sequence,
        S.Iterator.Element == HMCDUpsertableType,
        O: ObserverType,
        O.E == [HMCDResult]
    {
        serializeBlock({
            let upsertables = upsertables.map({$0})
            
            if upsertables.isNotEmpty {
                do {
                    let results = try self.convert(context, entityName, upsertables)
                    try self.saveUnsafely(context)
                    obs.onNext(results)
                    obs.onCompleted()
                } catch let e {
                    obs.onError(e)
                }
            } else {
                obs.onNext([])
                obs.onCompleted()
            }
        })
    }
    
    /// Perform an upsert operation for some upsertable data. For items that
    /// do not exist in the DB yet, we simply insert them.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    ///   - obs: An ObserverType instance.
    func upsert<U,S,O>(_ context: Context,
                       _ entityName: String,
                       _ upsertables: S,
                       _ obs: O) where
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == U,
        O: ObserverType,
        O.E == [HMCDResult]
    {
        let upsertables = upsertables.map({$0 as HMCDUpsertableType})
        return upsert(context, entityName, upsertables, obs)
    }
}

extension Reactive where Base == HMCDManager {
    
    /// Perform an upsert request on a Sequence of upsertable objects.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Observable instane.
    func upsert<S>(_ context: HMCDManager.Context,
                   _ entityName: String,
                   _ upsertables: S)
        -> Observable<[HMCDResult]> where
        S: Sequence, S.Iterator.Element == HMCDUpsertableType
    {
        return Observable<[HMCDResult]>.create({
            self.base.upsert(context, entityName, upsertables, $0)
            return Disposables.create()
        })
    }
    
    /// Perform an upsert request on a Sequence of upsertable objects.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value. representing the entity's name.
    ///   - upsertables: A Sequence of upsertable objects.
    /// - Returns: An Observable instane.
    func upsert<U,S>(_ context: HMCDManager.Context,
                     _ entityName: String,
                     _ upsertables: S)
        -> Observable<[HMCDResult]> where
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == U
    {
        return upsert(context, entityName, upsertables.map({$0 as HMCDUpsertableType}))
    }
}
