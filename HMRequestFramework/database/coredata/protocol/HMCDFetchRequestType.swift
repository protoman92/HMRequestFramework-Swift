//
//  HMCDFetchRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/23/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to provide the required
/// parameters for a CoreData fetch request.
public protocol HMCDFetchRequestType {
    
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
    
    /// Get the fetch limit for a fetch request.
    ///
    /// - Returns: An Int value.
    func fetchLimit() -> Int?
    
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
}

public extension HMCDFetchRequestType {
    
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
        
        // fetchLimit is an optional because we are not sure what CoreData's
        // default fetchLimit is. We don't want to set the limit unless the
        // request explicitly asks for one.
        if let limit = fetchLimit() {
            cdRequest.fetchLimit = limit
        }
        
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
}

