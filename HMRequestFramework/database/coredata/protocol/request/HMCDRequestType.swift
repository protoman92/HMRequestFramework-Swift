//
//  HMCDRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Request type for CoreData. Refer to HMCDOperation for a list of properties
/// used for each operation.
public protocol HMCDRequestType: HMDatabaseRequestType, HMCDFetchRequestType {
    
    /// Get the associated CoreData operation.
    ///
    /// - Returns: A HMCDOperation instance.
    func operation() throws -> HMCDOperation
    
    /// Get the data to be inserted. Only used for save operations
    ///
    /// NSManagedObject will first be reconstructed using a disposable context,
    /// and then saved. This is essentially "passing objects among contexts",
    /// but we do so with the help of Builders. There is no risk of bad access
    /// this way.
    ///
    /// - Returns: An Array of HMCDConvertibleType.
    /// - Throws: Exception if the data is not available.
    func insertedData() throws -> [HMCDObjectConvertibleType]
    
    /// Get the data to be upserted. Upsert works similarly to how insertion
    /// does, but it will also check for version-controlled objects if present.
    ///
    /// - Returns: An Array of HMCDConvertibleType.
    /// - Throws: Exception if the data is not available.
    func upsertedData() throws -> [HMCDUpsertableType]
    
    /// Get the data to be deleted. Only used for delete operations.
    ///
    /// The reason why we can specify exactly the data to delete (instead of
    /// passing a context with changes to be saved is that we can actually
    /// create a disposable context ourselves, populate it with data pulled
    /// from the DB using objectIDs and call said context's delete(_:) method
    /// without it throwing an Error.
    ///
    /// - Returns: An Array of HMCDObjectConvertibleType.
    /// - Throws: Exception if the data is not available.
    func deletedData() throws -> [HMCDObjectConvertibleType]
    
    /// Get the conflict strategy to be used in an update operation.
    ///
    /// - Returns: A Strategy instance.
    /// - Throws: Exception if the data is not available.
    func versionConflictStrategy() throws -> VersionConflict.Strategy
}

public extension HMCDRequestType {
        
    /// Get version update requests for some versionable objects.
    ///
    /// - Parameter versionables: A Sequence of versionable objects.
    /// - Returns: An Array of HMCDVersionUpdateRequest.
    /// - Throws: Exception if the operation fails.
    func updateRequest<S>(_ versionables: S) throws -> [HMCDVersionUpdateRequest] where
        S: Sequence, S.Element == HMCDVersionableType
    {
        let conflictStrategy = try versionConflictStrategy()
        
        return versionables.map({
            /// Do not set the original object yet (because we still haven't
            /// gotten access to it until we pull from DB).
            HMCDVersionUpdateRequest.builder()
                .with(edited: $0)
                .with(strategy: conflictStrategy)
                .build()
        })
    }
}
