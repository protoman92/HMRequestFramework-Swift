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
    HMCDKeyValueUpdatableType,
    HMCDPureObjectConvertibleType,
    HMCDUpsertableType {}

/// Use this for CoreData classes that require version control. Upsertable is
/// implied.
public protocol HMCDVersionableMasterType: HMCDObjectMasterType, HMCDVersionableType {}

/// Use this for PureObject classes that mirror CoreData classes.
public protocol HMCDPureObjectMasterType:
    // Instead of constructing the managed object to perform upserts, we can
    // simply use the primary key/value from the pure object.
    HMCDIdentifiableType,
    HMCDPureObjectType,
    HMCDPureObjectBuildableType {}

/// Use this for PureObject Builder classes.
public protocol HMCDPureObjectBuilderMasterType: HMCDPureObjectBuilderType {}
