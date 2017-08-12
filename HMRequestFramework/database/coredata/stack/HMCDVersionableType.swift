//
//  HMCDVersionableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Similar to HMVersionableType, customized for CoreData. They should be
/// identifiable without ObjectID (e.g. by having some other combination of
/// primary key/value), and also support updating inner values and version.
/// However, we should avoid such mutations as much as we can.
public protocol HMCDVersionableType:
    NSFetchRequestResult,           // Type can be retained in a fetch ops.
    HMVersionableType,              // Minimally versionable.
    HMCDConvertibleType,            // Reconstructible from a refetch.
    HMCDIdentifiableType,           // Identifiable in DB.
    HMCDKeyValueUpdatableType,      // Updatable using key-value pairs.
    HMCDVersionUpdatableType {}     // Updatable w.r.t version.

/// Classes that implement this protocol must be able to update version. Since
/// this protocol implies mutation, we should avoid using it as much as possible.
public protocol HMCDVersionUpdatableType {
    
    /// Update the version by mutating property.
    ///
    /// - Parameter version: A String value.
    func updateVersion(_ version: String?) throws
}

/// Similar to HMVersionBuildableType, customized for CoreData.
public protocol HMCDVersionBuildableType: HMCDObjectBuildableType {}

/// Similar to HMVersionBuilderType, customized for CoreData.
public protocol HMCDVersionBuilderType: HMCDObjectBuilderType {
    
    /// Set the version.
    ///
    /// - Parameter version: A String value denoting the version.
    /// - Returns: The current Builder instance.
    func with(version: String?) -> Self
}

public extension HMCDVersionBuildableType where
    Self: HMCDVersionableType,
    Builder: HMCDVersionBuilderType,
    Builder.Buildable == Self
{
    /// Clone the current object and assign a specified version to it.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - version: A String value.
    /// - Returns: The current Buildable instance.
    /// - Throws: Exception if the operation fails.
    public func cloneWithVersion(_ context: NSManagedObjectContext,
                                 _ version: String?) throws -> Self {
        return try cloneBuilder(context).with(version: version).build()
    }
    
    /// Clone the current object and bump version to one level higher.
    ///
    /// - Parameters context: A NSManagedObjectContext instance.
    /// - Returns: The current Buildable instance.
    @discardableResult
    public func cloneAndBumpVersion(_ context: NSManagedObjectContext) throws -> Self {
        return try cloneBuilder(context).with(version: oneVersionHigher()).build()
    }
}
