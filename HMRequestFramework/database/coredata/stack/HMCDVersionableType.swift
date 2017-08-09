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
public protocol HMCDVersionBuildableType: HMCDObjectBuildableType {
    associatedtype Builder: HMCDVersionBuilderType
}

/// Similar to HMVersionBuilderType, customized for CoreData.
public protocol HMCDVersionBuilderType: HMCDObjectBuilderType {
    associatedtype Buildable: HMCDVersionBuildableType
    
    /// Set the version.
    ///
    /// - Parameter version: A String value denoting the version.
    /// - Returns: The current Builder instance.
    func with(version: String?) -> Self
}

public extension HMCDVersionBuildableType where
    Self: HMCDVersionableType & HMCDPureObjectConvertibleType,
    Builder.PureObject == Self.PureObject
{
    /// Clone the current object and bump version to one level higher.
    ///
    /// - Returns: The current versionable object.
    @discardableResult
    public func cloneAndBumpVersion(_ context: NSManagedObjectContext) throws -> Builder {
        return try cloneBuilder(context).with(version: oneVersionHigher())
    }
}
