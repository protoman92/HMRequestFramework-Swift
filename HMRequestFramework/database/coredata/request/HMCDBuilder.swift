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
public protocol HMCDBuilder {
    associatedtype Base: HMCDParsableType
    
    func with(base: Base) -> Self
    
    func build() -> Base.CDClass
}

/// Classes that implement this protocol are usually NSManagedObject that
/// has in-built Builders.
public protocol HMCDBuildable {
    associatedtype Builder: HMCDBuilder
    
    static func builder(_ context: NSManagedObjectContext) throws -> Builder
}
