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
    associatedtype CDClass: HMCDObjectType
}

/// CoreData classes that implement this protocol must be able to transform
/// into a pure object (that does not inherit from NSManagedObject).
public protocol HMCDPureObjectConvertibleType {
    associatedtype PureObject: HMCDPureObjectType
    
    func asPureObject() -> PureObject
}

/// Pure object builders that implement this protocol must be able to copy
/// properties from a HMCDRepresentableType object into the current pure object.
public protocol HMCDPureObjectBuilderType: HMBuilderType {
    associatedtype Buildable: HMCDPureObjectType
    
    func with(representable: Buildable.CDClass) -> Self
}

/// Pure object classes that implement this protocol must have in-built Builder
/// classes.
public protocol HMCDPureObjectBuildableType: HMBuildableType {
    associatedtype Builder: HMCDPureObjectBuilderType
}

public extension HMCDPureObjectConvertibleType where
    PureObject: HMCDPureObjectBuildableType,
    PureObject.Builder.Buildable.CDClass == Self,
    PureObject.Builder.Buildable == PureObject
{
    /// With the right protocol constraints, we can directly implement this
    /// method by default.
    public func asPureObject() -> PureObject {
        return PureObject.builder().with(representable: self).build()
    }
}
