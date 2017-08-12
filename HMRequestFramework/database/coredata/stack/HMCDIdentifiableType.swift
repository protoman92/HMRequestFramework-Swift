//
//  HMCDIdentifiableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 31/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol should extend from NSManagedObject
/// and can be identified without using ObjectID.
public protocol HMCDIdentifiableType: HMIdentifiableType, HMCDObjectAliasType {}

public extension HMCDIdentifiableType {
    
    /// Check whether the current object is identifiable as some other 
    /// NSManagedObject instance.
    ///
    /// - Parameter object: A NSManagedObject instance.
    /// - Returns: A Bool value.
    public func identifiable(as object: NSManagedObject) -> Bool {
        let key = self.primaryKey()
        let value = self.primaryValue()
        
        if let oValue = object.value(forKey: key) {
            return value == String(describing: oValue)
        } else {
            return false
        }
    }
    
    /// Check whether the current object is identifiable as some other 
    /// NSManagedObject instance.
    ///
    /// - Parameter object: A HMCDObjectAliasType instance.
    /// - Returns: A Bool value.
    public func identifiable(as object: HMCDObjectAliasType) -> Bool {
        return identifiable(as: object.asManagedObject())
    }
}

