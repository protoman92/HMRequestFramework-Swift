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
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC
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
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC
    {
        // The original object should be managed by the parameter context,
        // or this will raise an error.
        context.delete(original)
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
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC
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
    ///   - editedObjects: A Sequence of versioned objects.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the operation fails.
    public func updateVersion<VC,S,O>(_ context: NSManagedObjectContext,
                                      _ editedObjects: S,
                                      _ obs: O) throws where
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC,
        S: Sequence,
        S.Iterator.Element == VC,
        O: ObserverType,
        O.E == Try<Void>
    {
        performOnContextThread(mainContext) {
            for edited in editedObjects {
                do {
                    
                }
            }
        }
    }
}
