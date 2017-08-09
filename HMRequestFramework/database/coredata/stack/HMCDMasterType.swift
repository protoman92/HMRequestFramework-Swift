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
    HMCDObjectBuildableType,
    HMCDPureObjectConvertibleType
{
    associatedtype Builder: HMCDObjectBuilderMasterType
    associatedtype PureObject: HMCDPureObjectMasterType
}

/// CoreData object Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDObjectBuilderMasterType: HMCDObjectBuilderType {
    associatedtype PureObject: HMCDPureObjectMasterType
}

/// PureObject classes should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDPureObjectMasterType:
    HMCDPureObjectType,
    HMCDPureObjectBuildableType
{
    associatedtype CDClass: HMCDObjectMasterType
    associatedtype Builder: HMCDPureObjectBuilderMasterType
}

/// PureObject Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDPureObjectBuilderMasterType: HMCDPureObjectBuilderType {
    associatedtype Buildable: HMCDPureObjectMasterType
}

/// Versionable classes should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDVersionableMasterType: HMCDVersionableType, HMCDVersionBuildableType {
    associatedtype Builder: HMCDVersionableBuilderMasterType
}

/// Versionable Builders should implement this protocol to guarantee conformance
/// to required sub-protocols.
public protocol HMCDVersionableBuilderMasterType: HMCDVersionBuilderType {
    associatedtype Buildable: HMCDVersionableMasterType
}
