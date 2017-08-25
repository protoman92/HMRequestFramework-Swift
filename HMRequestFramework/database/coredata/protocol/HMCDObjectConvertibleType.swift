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
public protocol HMCDObjectConvertibleType {
    
    /// Convert the current object into a NSManagedObject. If this is already
    /// a NSManagedObject, clone it and insert the clone into the specified
    /// context. We can use this technique to "pass" objects among different
    /// contexts.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: A NSManagedObject instance.
    /// - Throws: Exception if the conversion fails.
    func asManagedObject(_ context: NSManagedObjectContext) throws -> NSManagedObject
}

public extension HMCDObjectConvertibleType where
    Self: HMCDObjectBuildableType,
    Self.Builder.Buildable == Self
{
    public func asManagedObject(_ context: NSManagedObjectContext) throws
        -> NSManagedObject
    {
        return try cloneBuilder(context).build()
    }
}

// Pure objects can implement HMCDObjectConvertibleType as well, given their
// CoreData counterparts implement certain protocols.
public extension HMCDObjectConvertibleType where
    Self: HMCDPureObjectType,
    Self.CDClass: HMCDObjectBuildableType,
    Self.CDClass.Builder.PureObject == Self
{
    public func asManagedObject(_ context: NSManagedObjectContext) throws
        -> NSManagedObject
    {
        return try CDClass.builder(context).with(pureObject: self).build()
    }
}

