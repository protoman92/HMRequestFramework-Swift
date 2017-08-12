//
//  HMCDMasterType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this for CoreData classes that do not need upsert/version control.
public protocol HMCDObjectMasterType:
    HMCDObjectType,
    HMCDObjectConvertibleType,
    HMCDObjectBuildableType,
    HMCDPureObjectConvertibleType {}

/// Use this for CoreData Builder classes.
public protocol HMCDObjectBuilderMasterType: HMCDObjectBuilderType {}

/// Use this for CoreData classes that require upsert.
public protocol HMCDUpsertableMasterType:
    HMCDObjectMasterType,
    HMCDUpsertableType {}

/// Use this for CoreData classes that require version control. Upsertable is
/// implied.
public protocol HMCDVersionableMasterType:
    HMCDUpsertableMasterType,
    HMCDVersionableType,
    HMCDVersionBuildableType {}

/// Use this for PureObject classes that mirror CoreData classes.
public protocol HMCDPureObjectMasterType:
    HMCDPureObjectType,
    HMCDPureObjectBuildableType {}

/// Use this for PureObject Builder classes.
public protocol HMCDPureObjectBuilderMasterType: HMCDPureObjectBuilderType {}

