//
//  HMCDBuilder.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 28/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to construct a CoreData
/// NSManagedObject.
///
/// This protocol is useful when we have 2 parallel classes, one of which
/// inherits from NSManagedObject and the other simply copies the former's
/// properties. The upper layers should only be aware of the latter, so when
/// we wish to save it to CoreData, we will have methods to implicitly convert
/// the pure data class into a CoreData-compatible object.
///
/// The with(base:) method will copy all attributes from the pure data object
/// into the newly constructor CoreData object.
public protocol HMCDBuilder {
    associatedtype Base: HMCDParsableType
    
    func with(base: Base) -> Self
    
    func build() -> Base.CDClass
}

/// Classes that implement this protocol are usually NSManagedObject that
/// has in-built Builders that implement HMCDBuilder. It should also be
/// convertible to a pure data object.
public protocol HMCDBuildable {
    associatedtype Builder: HMCDBuilder
    
    static func builder(_ context: NSManagedObjectContext) throws -> Builder
    
    /// Convert the current CoreData object into the base data class.
    ///
    /// - Returns: A Builder.Base instance.
    func asBase() -> Builder.Base
}
