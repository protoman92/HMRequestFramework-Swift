//
//  HMCDVersionableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Similar to HMVersionableType, customized for CoreData.
public protocol HMCDVersionableType: HMVersionableType {}

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
    /// Clone the current object and bump version to one level higher.
    ///
    /// - Returns: The current versionable object.
    @discardableResult
    public func cloneAndBumpVersion(_ context: NSManagedObjectContext) throws -> Builder {
        return try cloneBuilder(context).with(version: oneVersionHigher())
    }
}
