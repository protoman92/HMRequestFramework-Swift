//
//  HMCDManager+Version+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

// Just a bit of utility here, not going to expose publicly.
fileprivate extension HMVersionUpdateRequest where VC == HMCDVersionableType {
    
    /// Check if the current request possesses an edited object.
    ///
    /// - Parameter obj: A HMCDIdentifiableType instance.
    /// - Returns: A Bool value.
    fileprivate func ownsEditedVC(_ obj: HMCDIdentifiableType) -> Bool {
        return (try? editedVC().identifiable(as: obj)) ?? false
    }
}

public extension HMCDManager {
    
    /// Resolve version conflict using the specified strategy. This operation
    /// is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - request: A HMVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func resolveVersionConflictUnsafely(
        _ context: Context,
        _ request: HMCDVersionUpdateRequest) throws
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
    ///   - context: A Context instance.
    ///   - request: A HMCDVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func attempVersionUpdateUnsafely(_ context: Context,
                                     _ request: HMCDVersionUpdateRequest) throws
    {
        let original = try request.originalVC()
        let edited = try request.editedVC()
        let newVersion = edited.oneVersionHigher()
        
        // The original object should be managed by the parameter context.
        // We update the original object by mutating it - under other circumstances,
        // this is not recommended.
        try original.update(from: edited)
        try original.updateVersion(newVersion)
    }
    
    /// Update some object with version bump. Resolve any conflict if necessary.
    /// This operation is not thread-safe.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - request: A HMVersionUpdateRequest instance.
    /// - Throws: Exception if the operation fails.
    func updateVersionUnsafely(_ context: Context,
                               _ request: HMCDVersionUpdateRequest) throws {
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
    
    /// Perform update on the identifiables, insert them into the specified
    /// context and and get the results back.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    /// - Throws: Exception if the operation fails.
    func convert<S>(_ context: Context,
                    _ entityName: String,
                    _ requests: S) throws -> [HMCDResult] where
        S: Sequence, S.Element == HMCDVersionUpdateRequest
    {
        var requests = requests.sorted(by: {$0.0.compare(against: $0.1)})
        
        // It's ok for these requests not to have the original object. We will
        // get them right below.
        let ids: [HMCDIdentifiableType] = requests.flatMap({try? $0.editedVC()})
        var originals = try self.blockingFetchIdentifiables(context, entityName, ids)
        var results: [HMCDResult] = []
        
        // We also need an Array of VC to store items that cannot be found in
        // the DB yet.
        var nonExisting: [HMCDObjectConvertibleType] = []
        
        for item in ids {
            if
                let oIndex = originals.index(where: item.identifiable),
                let rIndex = requests.index(where: {($0.ownsEditedVC(item))}),
                let original = originals.element(at: oIndex),
                let request = requests.element(at: rIndex)?
                    .cloneBuilder()
                    
                    // The cast here is unfortunate, but we have to do it to
                    // avoid having to define a concrete class that extends
                    // NSManagedObject and implements HMCDVersionableType.
                    // When the object is fetched from database, it retains its
                    // original type (thanks to entityName), but is masked under
                    // NSManagedObject. We should expect it to be a subtype of
                    // HMCDVersionableType.
                    .with(original: original as? HMCDVersionableType)
                    .build()
            {
                let result: HMCDResult
                
                do {
                    try self.updateVersionUnsafely(context, request)
                    result = HMCDResult.just(item)
                } catch let e {
                    result = HMCDResult.builder()
                        .with(object: item)
                        .with(error: e)
                        .build()
                }
                
                results.append(result)
                originals.remove(at: oIndex)
                requests.remove(at: rIndex)
            } else {
                nonExisting.append(item)
            }
        }
        
        // For items that do not exist in the DB yet, simply save them. Since
        // these objects are convertible, we can reconstruct them as NSManagedObject
        // instances and insert into the specified context.
        results.append(contentsOf: convert(context, nonExisting))
        
        return results
    }
}

public extension HMCDManager {
    
    /// Update a Sequence of versioned objects and save to memory. It is better
    /// not to call this method on too many objects, because context.save()
    /// will be called just as many times.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func updateVersion<S,O>(_ context: Context,
                            _ entityName: String,
                            _ requests: S,
                            _ opMode: HMCDOperationMode,
                            _ obs: O) -> Disposable where
        S: Sequence,
        S.Element == HMCDVersionUpdateRequest,
        O: ObserverType,
        O.E == [HMCDResult]
    {
        Preconditions.checkNotRunningOnMainThread(requests)
        
        performOperation(opMode, {
            let requests = requests.map({$0})
            
            if requests.isNotEmpty {
                do {
                    let results = try self.convert(context, entityName, requests)
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
        
        return Disposables.create()
    }
}

extension Reactive where Base == HMCDManager {
    
    /// Update a Sequence of versioned objects and save to memory.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - entityName: A String value representing the entity's name.
    ///   - requests: A Sequence of HMVersionUpdateRequest.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<S>(_ context: HMCDManager.Context,
                                 _ entityName: String,
                                 _ requests: S,
                                 _ opMode: HMCDOperationMode = .queued)
        -> Observable<[HMCDResult]> where
        S: Sequence, S.Element == HMCDVersionUpdateRequest
    {
        return Observable.create({
            self.base.updateVersion(context, entityName, requests, opMode, $0)
        })
    }
}
