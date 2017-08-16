//
//  HMCDRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Request type for CoreData. Refer to CoreDataOperation for a list of properties
/// used for each operation.
public protocol HMCDRequestType: HMDatabaseRequestType {
    
    /// Get the NSManagedObject entity description.
    ///
    /// - Returns: A String value.
    func entityName() throws -> String
    
    /// Get NSPredicate.
    ///
    /// - Returns: A NSPredicate instance.
    func predicate() throws -> NSPredicate
    
    /// Get an Array of NSSortDescriptor.
    ///
    /// - Returns: An Array of NSSortDescriptor.
    func sortDescriptors() throws -> [NSSortDescriptor]
    
    /// Get the associated CoreData operation.
    ///
    /// - Returns: A CoreDataOperation instance.
    func operation() throws -> CoreDataOperation
    
    /// Get the result type for a fetch request.
    ///
    /// - Returns: A NSFetchRequestResultType instance.
    func fetchResultType() -> NSFetchRequestResultType?
    
    /// Get the propertiesToFetch for a NSFetchRequest.
    ///
    /// - Returns: An Array of Any.
    func fetchProperties() -> [Any]?
    
    /// Get the propertiesToGroupBy for a NSFetchRequest.
    ///
    /// - Returns: An Array of Any.
    func fetchGroupBy() -> [Any]?
    
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
    /// passing a context with changes to be saved, as is the case for save
    /// and upsert) is that we can actually create a disposable context ourselves,
    /// populate it with data pulled from the DB using objectIDs and call said
    /// context's delete(_:) method without it throwing an Error.
    ///
    /// - Returns: An Array of HMCDObjectConvertibleType.
    /// - Throws: Exception if the data is not available.
    func deletedData() throws -> [HMCDObjectConvertibleType]
    
    /// Get the conflict strategy to be used in an update operation/
    ///
    /// - Returns: A Strategy instance.
    /// - Throws: Exception if the data is not available.
    func versionConflictStrategy() throws -> VersionConflict.Strategy
}

public extension HMCDRequestType {
    
    /// Get the associated fetch request.
    ///
    /// - Returns: A NSFetchRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func fetchRequest<Val>() throws -> NSFetchRequest<Val> where
        Val: NSFetchRequestResult
    {
        let description = try entityName()
        let resultType = fetchResultType() ?? .managedObjectResultType
        let propertiesToFetch = fetchProperties()
        let propertiesToGroupBy = fetchGroupBy()
        let cdRequest = NSFetchRequest<Val>(entityName: description)
        cdRequest.predicate = try predicate()
        cdRequest.sortDescriptors = try sortDescriptors()
        cdRequest.resultType = resultType
        cdRequest.propertiesToFetch = propertiesToFetch
        cdRequest.propertiesToGroupBy = propertiesToGroupBy
        return cdRequest
    }
    
    /// Get the associated fetch request, but do not specify any subtype.
    ///
    /// - Returns: A NSFetchRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func untypedFetchRequest() throws -> NSFetchRequest<NSFetchRequestResult> {
        return try fetchRequest()
    }
    
    /// Get the associated fetch request.
    ///
    /// - Parameter cls: The Val class type.
    /// - Returns: A NSFetchRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func fetchRequest<Val>(_ cls: Val.Type) throws -> NSFetchRequest<Val> where
        Val: NSFetchRequestResult
    {
        return try fetchRequest()
    }
    
    /// Get the associated fetch request.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: A NSFetchRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func fetchRequest<PO>(_ cls: PO.Type) throws -> NSFetchRequest<PO.CDClass> where
        PO: HMCDPureObjectType
    {
        return try fetchRequest(cls.CDClass.self)
    }
    
    /// Get version update requests for some versionable objects.
    ///
    /// - Parameter versionables: A Sequence of versionable objects.
    /// - Returns: An Array of HMCDVersionUpdateRequest.
    /// - Throws: Exception if the operation fails.
    public func updateRequest<S>(_ versionables: S) throws -> [HMCDVersionUpdateRequest] where
        S: Sequence, S.Iterator.Element == HMCDVersionableType
    {
        let conflictStrategy = try versionConflictStrategy()
        
        return versionables.map({
            HMCDVersionUpdateRequest.builder()
                .with(edited: $0)
                .with(strategy: conflictStrategy)
                .build()
        })
    }
}
