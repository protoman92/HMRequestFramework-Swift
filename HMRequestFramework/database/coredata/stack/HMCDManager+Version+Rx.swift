//
//  HMCDManager+VersionExtension.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Produce a strategy based on some inputs.
public typealias StrategyFn<T> = (Int, T) throws -> VersionConflict.Strategy

public extension HMCDManager {
    
    /// Resolve version conflict using the specified strategy. This operation
    /// is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func resolveVersionConflictUnsafely<VC>(_ context: NSManagedObjectContext,
                                            _ original: VC,
                                            _ edited: VC,
                                            _ strategy: VersionConflict.Strategy)
        throws where
        VC: HMCDObjectAliasType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject
    {
        switch strategy {
        case .error:
            throw VersionConflict.Exception.builder()
                .with(existingVersion: original.currentVersion())
                .with(conflictVersion: edited.currentVersion())
                .build()
            
        case .ignore:
            try updateVersionUnsafely(context, original, edited)
        }
    }
    
    /// Perform version update and delete existing object in the DB. This step
    /// assumes that version comparison has been carried out and all conflicts
    /// have been resolved.
    ///
    /// This operation is not thread-safe.
    ///
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func updateVersionUnsafely<VC>(_ context: NSManagedObjectContext,
                                   _ original: VC,
                                   _ edited: VC) throws where
        VC: HMCDObjectAliasType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject
    {
        // The original object should be managed by the parameter context,
        // or this will raise an error.
        context.delete(original.asManagedObject())
        try edited.cloneAndBumpVersion(context)
        try saveUnsafely(context)
    }
    
    /// Update some object with version bump. Resolve any conflict if necessary.
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func updateVersionUnsafely<VC>(_ context: NSManagedObjectContext,
                                   _ original: VC,
                                   _ edited: VC,
                                   _ strategy: VersionConflict.Strategy)
        throws where
        VC: HMCDObjectAliasType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject
    {
        let originalVersion = original.currentVersion()
        let editedVersion = edited.currentVersion()
        
        if originalVersion == editedVersion {
            try updateVersionUnsafely(context, original, edited)
        } else {
            try resolveVersionConflictUnsafely(context, original, edited, strategy)
        }
    }
}

public extension HMCDManager {
    
    /// Update a Sequence of versioned objects and save to memory. It is better
    /// not to call this method on too many objects, because context.save()
    /// will be called just as many times.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategyFn: A strategy producer.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S,O>(_ context: NSManagedObjectContext,
                                      _ entityName: String,
                                      _ identifiables: S,
                                      _ strategyFn: @escaping StrategyFn<VC>,
                                      _ obs: O) where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC,
        O: ObserverType,
        O.E == [Try<Void>]
    {
        performOnContextThread(mainContext) {
            do {
                let originals = try self.blockingRefetch(context, entityName, identifiables)
                var results: [Try<Void>] = []
                
                for (index, id) in identifiables.enumerated() {
                    if let o = originals.first(where: id.identifiable) {
                        do {
                            let strategy = try strategyFn(index, id)
                            try self.updateVersionUnsafely(context, o, id, strategy)
                            results.append(Try.success(()))
                        } catch let e {
                            results.append(Try.failure(e))
                        }
                    }
                }
                
                obs.onNext(results)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDManager {
    /// Update a Sequence of versioned objects using a specified strategy and
    /// save to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategy: A Strategy instance.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S,O>(_ context: NSManagedObjectContext,
                                      _ entityName: String,
                                      _ identifiables: S,
                                      _ strategy: VersionConflict.Strategy,
                                      _ obs: O) where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC,
        O: ObserverType,
        O.E == [Try<Void>]
    {
        updateVersion(context, entityName, identifiables, {_ in strategy}, obs)
    }
}

extension Reactive where Base: HMCDManager {
    
    /// Update a Sequence of versioned objects and save to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategyFn: A strategy producer.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ context: NSManagedObjectContext,
                                    _ entityName: String,
                                    _ identifiables: S,
                                    _ strategyFn: @escaping StrategyFn<VC>)
        -> Observable<[Try<Void>]> where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC
    {
        return Observable<[Try<Void>]>.create({
            self.base.updateVersion(context, entityName, identifiables, strategyFn, $0)
            return Disposables.create()
        })
    }
    
    /// Update a Sequence of versioned objects and save to memory with a default
    /// context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategyFn: A strategy producer.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ entityName: String,
                                    _ identifiables: S,
                                    _ strategyFn: @escaping StrategyFn<VC>)
        -> Observable<[Try<Void>]> where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC
    {
        let context = base.disposableObjectContext()
        return updateVersion(context, entityName, identifiables, strategyFn)
    }
}

extension Reactive where Base: HMCDManager {
    
    /// Update a Sequence of versioned objects using a specified strategy and
    /// save to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategy: A Strategy instance.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ context: NSManagedObjectContext,
                                    _ entityName: String,
                                    _ identifiables: S,
                                    _ strategy: VersionConflict.Strategy)
        -> Observable<[Try<Void>]> where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC
    {
        return updateVersion(context, entityName, identifiables, {_ in strategy})
    }
    
    /// Update a Sequence of versioned objects using a specified strategy and
    /// save to memory with a default context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - identifiables: A Sequence of versioned objects.
    ///   - strategy: A Strategy producer.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ entityName: String,
                                    _ identifiables: S,
                                    _ strategy: VersionConflict.Strategy)
        -> Observable<[Try<Void>]> where
        VC: HMCDIdentifiableType,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.PureObject == VC.Builder.PureObject,
        S: Sequence,
        S.Iterator.Element == VC
    {
        return updateVersion(entityName, identifiables, {_ in strategy})
    }
}
