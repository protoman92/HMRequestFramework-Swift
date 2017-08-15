//
//  HMCDObjectAliasType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 10/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// CoreData classes must implement this protocol.
public protocol HMCDObjectAliasType {
    
    /// Convert the current alias into NSManagedObject.
    ///
    /// - Returns: A NSManagedObject instance.
    func asManagedObject() -> NSManagedObject
}

public extension HMCDObjectAliasType where Self: NSManagedObject {
    public func asManagedObject() -> NSManagedObject {
        return self
    }
}

extension NSManagedObject: HMCDObjectAliasType {}
