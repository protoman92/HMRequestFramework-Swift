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

// Just a bit of utility here, not going to expose publicly.
fileprivate extension HMVersionUpdateRequest where VC: HMCDIdentifiableType {
    
    /// Check if the current request possesses an edited object.
    ///
    /// - Parameter obj: A VC instance.
    /// - Returns: A Bool value.
    fileprivate func ownsEditedVC(_ obj: VC) -> Bool {
        return (try? editedVC().identifiable(as: obj)) ?? false
    }
}

public extension HMCDManager {
    
    /// Resolve version conflict using the specified strategy. This operation
    /// is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A HMVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func resolveVersionConflictUnsafely<VC>(
        _ context: NSManagedObjectContext,
        _ request: HMVersionUpdateRequest<VC>) throws where
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC
    {
        let original = try request.originalVC()
        let edited = try request.editedVC()
        
        switch request.conflictStrategy() {
        case .error:
            throw VersionConflict.Exception.builder()
                .with(existingVersion: original.currentVersion())
                .with(conflictVersion: edited.currentVersion())
                .build()
            
        case .overwrite:
            try attempVersionUpdateUnsafely(context, request)
            
        case .takePreferable:
            if try edited.hasPreferableVersion(over: original) {
                try attempVersionUpdateUnsafely(context, request)
            }
        }
    }
    
    /// Perform version update and delete existing object in the DB. This step
    /// assumes that version comparison has been carried out and all conflicts
    /// have been resolved.
    ///
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A HMVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func attempVersionUpdateUnsafely<VC>(
        _ context: NSManagedObjectContext,
        _ request: HMVersionUpdateRequest<VC>) throws where
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC
    {
        let original = try request.originalVC()
        let edited = try request.editedVC()
        
        // The original object should be managed by the parameter context,
        // or this will raise an error.
        context.delete(original.asManagedObject())
        
        // When we call this method, we bump the edited object's version and
        // insert the new clone in the specified context. Calling context.save()
        // will propagate this clone upwards.
        try edited.cloneAndBumpVersion(context)
    }
    
    /// Update some object with version bump. Resolve any conflict if necessary.
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - request: A HMVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func updateVersionUnsafely<VC>(
        _ context: NSManagedObjectContext,
        _ request: HMVersionUpdateRequest<VC>) throws where
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC
    {
        let originalVersion = try request.originalVC().currentVersion()
        let editedVersion = try request.editedVC().currentVersion()
        
        if originalVersion == editedVersion {
            try attempVersionUpdateUnsafely(context, request)
        } else {
            try resolveVersionConflictUnsafely(context, request)
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
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the operation fails.
    func updateVersion<VC,S,O>(_ context: NSManagedObjectContext,
                               _ entityName: String,
                               _ requests: S,
                               _ obs: O) where
        VC: HMCDConvertibleType,
        VC: HMCDIdentifiableType,
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC,
        S: Sequence,
        S.Iterator.Element == HMVersionUpdateRequest<VC>,
        O: ObserverType,
        O.E == [HMResult<VC>]
    {
        performOnContextThread(mainContext) {
            do {
                // It's ok for these requests not to have the original object.
                // We will get them right below.
                let identifiables = requests.flatMap({try? $0.editedVC()})
                let originals = try self.blockingRefetch(context, entityName, identifiables)
                var results: [HMResult<VC>] = []
                
                // We also need an Array of VC to store items that cannot be
                // found in the DB yet.
                var nonExisting: [VC] = []
                
                for item in identifiables {
                    if
                        let original = originals.first(where: item.identifiable),
                        let request = requests.first(where: {($0.ownsEditedVC(item))})?
                            .cloneBuilder()
                            .with(original: original)
                            .with(edited: item)
                            .build()
                    {
                        let result: HMResult<VC>
                        
                        do {
                            try self.updateVersionUnsafely(context, request)
                            result = HMResult<VC>.builder().with(object: item).build()
                        } catch let e {
                            result = HMResult<VC>.builder()
                                .with(object: item)
                                .with(error: e)
                                .build()
                        }
                        
                        results.append(result)
                    } else {
                        nonExisting.append(item)
                    }
                }
                
                // For items that do not exist in the DB yet, simply save them.
                // Since these objects are convertible, we can reconstruct them
                // as NSManagedObject instances and insert into the specified
                // context.
                results.append(contentsOf: self.convert(context, nonExisting))
                
                // When we save this context, the updates and insertions will
                // be committed to upstream.
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
    
    /// Update a Sequence of versioned objects and save to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ context: NSManagedObjectContext,
                                    _ entityName: String,
                                    _ requests: S)
        -> Observable<[HMResult<VC>]> where
        VC: HMCDConvertibleType,
        VC: HMCDIdentifiableType,
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC,
        S: Sequence,
        S.Iterator.Element == HMVersionUpdateRequest<VC>
    {
        return Observable<[HMResult<VC>]>.create({
            self.base.updateVersion(context, entityName, requests, $0)
            return Disposables.create()
        })
    }
    
    /// Update a Sequence of versioned objects and save to memory with a default
    /// context.
    ///
    /// - Parameters:
    ///   - entityName: A String value representing the entity's name.
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    ///   - strategyFn: A strategy producer.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S>(_ entityName: String, _ requests: S)
        -> Observable<[HMResult<VC>]> where
        VC: HMCDConvertibleType,
        VC: HMCDIdentifiableType,
        VC: HMCDVersionableType,
        VC: HMCDVersionBuildableType,
        VC.Builder: HMCDVersionBuilderType,
        VC.Builder.Buildable == VC,
        S: Sequence,
        S.Iterator.Element == HMVersionUpdateRequest<VC>
    {
        let context = base.disposableObjectContext()
        return updateVersion(context, entityName, requests)
    }
}
