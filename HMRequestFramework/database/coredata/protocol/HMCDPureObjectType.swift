//
//  HMCDPureObjectType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Model classes that can be derived from a NSManagedObject subtype should
/// implement this protocol to constrain themselves to specific CD types. This
/// allows us to hide the assocated CD classes, making DB swapping easier in the
/// future.
///
/// These objects should simply contain data that mirror their NSManagedObject
/// counterparts.
public protocol HMCDPureObjectType {
    associatedtype CDClass: NSManagedObject, HMCDObjectType
}

/// Pure object builders that implement this protocol must be able to copy
/// properties from a HMCDObjectType object into the current pure object.
public protocol HMCDPureObjectBuilderType: HMBuilderType where
    Buildable: HMCDPureObjectType
{
    func with(cdObject: Buildable.CDClass) -> Self
}

/// Pure object classes that implement this protocol must have in-built Builder
/// classes.
public protocol HMCDPureObjectBuildableType: HMBuildableType where
    Builder: HMCDPureObjectBuilderType {}
