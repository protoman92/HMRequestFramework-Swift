//
//  HMVersionableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must provide version properties that
/// can be updated and compared. This is done so to prevent race conditions when
/// we read/modify/save some objects from/to the DB.
public protocol HMVersionableType {
    
    /// Get the current version.
    ///
    /// - Returns: A String value.
    func currentVersion() -> String?
    
    /// Get the version that is one level up the current one.
    ///
    /// - Returns: A String value.
    func oneVersionHigher() -> String?
    
    /// Check if this object's version is preferable over that of another object.
    ///
    /// - Parameter obj: A HMVersionableType instance.
    /// - Returns: A Bool value.
    /// - Throws: Exception if the operation fails.
    func hasPreferableVersion(over obj: Self) throws -> Bool
}

/// Classes that implement this protocol should be buildable with a builder that
/// exposes methods to bump versions.
public protocol HMVersionBuildableType: HMBuildableType {}

/// Builders that implement this protocol must be able to bump versions for
/// the associated Buildable. The version here is kept as a String for simplicity.
public protocol HMVersionBuilderType: HMBuilderType {
    
    /// Set the version.
    ///
    /// - Parameter version: A String value denoting the version.
    /// - Returns: The current Builder instance.
    func with(version: String?) -> Self
}

public extension HMVersionBuildableType where
    Self: HMVersionableType,
    Builder: HMVersionBuilderType,
    Builder.Buildable == Self
{
    /// Clone the current object and bump version to one level higher.
    ///
    /// - Returns: The current versionable object.
    public func cloneAndBumpVersion() -> Self {
        return cloneBuilder().with(version: oneVersionHigher()).build()
    }
}
