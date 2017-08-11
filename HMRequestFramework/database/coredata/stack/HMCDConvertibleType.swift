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
public protocol HMCDConvertibleType {
    
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

public extension HMCDConvertibleType where
    Self: HMCDObjectBuildableType,
    Self.Builder.Buildable == Self
{
    public func asManagedObject(_ context: NSManagedObjectContext) throws -> NSManagedObject {
        return try cloneBuilder(context).build()
    }
}
