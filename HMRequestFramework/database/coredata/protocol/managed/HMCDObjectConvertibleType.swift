//
//  HMCDConvertibleType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 10/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to convert itself into
/// a NSManagedObject.
public protocol HMCDObjectConvertibleType: HMCDTypealiasType {
    
    /// Convert the current object into a NSManagedObject. If this is already
    /// a NSManagedObject, clone it and insert the clone into the specified
    /// context. We can use this technique to "pass" objects among different
    /// contexts.
    ///
    /// - Parameter context: A Context instance.
    /// - Returns: A NSManagedObject instance.
    /// - Throws: Exception if the conversion fails.
    func asManagedObject(_ context: Context) throws -> NSManagedObject
    
    /// Get the string representation of the current object, so that when this
    /// object to converted to a managed object, we should know how to fetch
    /// it again. This is especially useful for HMCDResult because it is not
    /// advisable to publish a constructed CD object lest it is deallocated
    /// unexpectedly.
    ///
    /// We can return anything here as long as it can be used to identity this
    /// object. We could also just return the primary value if this object
    /// conforms to HMCDIdentifiableType.
    ///
    /// - Returns: A String value.
    func stringRepresentationForResult() -> String
}

/// We need to implement this extension because CoreData objects are not allowed
/// to changed contexts. In order to replicate an object across different
/// contexts, we must create a new one in the receiving context and copy all
/// properties from the current object.
public extension HMCDObjectConvertibleType where
    Self: HMCDObjectType, Self: HMCDKeyValueUpdatableType
{
    public func asManagedObject(_ context: Context) throws -> NSManagedObject {
        let cdObject = try Self.init(context)
        try cdObject.update(from: self)
        return cdObject.asManagedObject()
    }
}

// Pure objects can implement HMCDObjectConvertibleType as well, given their
// CoreData counterparts implement certain protocols.
public extension HMCDObjectConvertibleType where
    Self: HMCDPureObjectType,
    Self.CDClass: HMCDPureObjectConvertibleType,
    Self.CDClass.PureObject == Self
{
    public func asManagedObject(_ context: Context) throws -> NSManagedObject {
        let cdObject = try CDClass.init(context)
        cdObject.mutateWithPureObject(self)
        return cdObject.asManagedObject()
    }
}
