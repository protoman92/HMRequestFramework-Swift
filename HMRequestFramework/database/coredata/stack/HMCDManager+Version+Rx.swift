//
//  HMCDManager+VersionExtension.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

public extension HMCDManager {
    
    /// Resolve version conflict using the specified strategy.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func resolveVersionConflict<VC>(_ context: NSManagedObjectContext,
                                    _ original: VC,
                                    _ edited: VC,
                                    _ strategy: VersionConflict.Strategy) throws where
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC
    {
        switch strategy {
        case .error:
            fatalError("Not implemented")
            
        case .ignore:
            fatalError("Not implemented")
        }
    }
    
    /// Perform version update and delete existing object in the DB.
    ///
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func updateVersion<VC>(_ context: NSManagedObjectContext,
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
    }
    
    /// Update some object with version bump.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - original: The original object as persisted in the DB.
    ///   - edited: The edited object to be updated.
    ///   - strategy: A Version conflict strategy instance.
    /// - Throws: Exception if the operation fails.
    func markUpdated<VC>(_ context: NSManagedObjectContext,
                         _ original: VC,
                         _ edited: VC,
                         _ strategy: VersionConflict.Strategy) throws where
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC
    {
        let originalVersion = original.currentVersion()
        let editedVersion = edited.currentVersion()
        
        if originalVersion == editedVersion {
            try updateVersion(context, original, edited)
        } else {
            try resolveVersionConflict(context, original, edited, strategy)
        }
    }
    
    public func updateVersionUnsafely<VC,S>(_ context: NSManagedObjectContext,
                                            _ edited: S) throws where
        VC: NSManagedObject,
        VC: HMCDPureObjectConvertibleType,
        VC: HMCDVersionableType & HMCDVersionBuildableType,
        VC.PureObject == VC.Builder.PureObject,
        VC.Builder.Buildable == VC,
        S: Sequence,
        S.Iterator.Element == VC
    {
        
    }
}
