//
//  HMCDMasterType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// CoreData classes should implement this protocol to guarantee conformance to
/// required sub-protocols.
public protocol HMCDObjectMasterType:
    HMCDObjectType,
    HMCDConvertibleType,
    HMCDObjectBuildableType,
    HMCDPureObjectConvertibleType {}

/// CoreData object Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDObjectBuilderMasterType: HMCDObjectBuilderType {}

/// PureObject classes should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDPureObjectMasterType:
    HMCDPureObjectType,
    HMCDPureObjectBuildableType
{}

/// PureObject Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDPureObjectBuilderMasterType: HMCDPureObjectBuilderType {}

/// Versionable classes should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDVersionableMasterType:
    HMCDObjectMasterType,
    HMCDUpdatableType,
    HMCDVersionableType,
    HMCDVersionUpdatableType,
    HMCDVersionBuildableType {}

/// Versionable Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDVersionableBuilderMasterType:
    HMCDObjectBuilderMasterType,
    HMCDVersionBuilderType {}
