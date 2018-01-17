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
    
    /// Initially, the CDClass also inherits from NSManagedObject, but I decided
    /// to remove that constraint in order to access the init(_:) method from
    /// HMCDObjectType conformance (Otherwise, the compiler will complain about
    /// duplicate init methods, since there is also one with similar signature
    /// but only available from iOS 10.0+).
    associatedtype CDClass: HMCDObjectType
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
///
/// You may notice that pure objects need builders, but managed objects do not.
/// In the old implementation of this framework, managed objects also had to
/// implement the builder pattern (with their corresponding cloneBuilder(_:)).
/// However, even with the builders there was no way to enforce immutability
/// for those objects, since they can simply call setValue(forKey:) to mutate
/// internal state. Therefore, builders for managed objects have been scrapped
/// to simplify the parallel object model.
public protocol HMCDPureObjectBuildableType: HMBuildableType where
    Builder: HMCDPureObjectBuilderType {}
