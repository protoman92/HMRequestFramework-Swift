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
public protocol HMCDIdentifiableType:
    HMIdentifiableType,             // Identifiable by primary key-value pair.
    HMCDObjectConvertibleType {}    // Reconstructible as NSManagedObject.

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
    
    /// Compare the current item with another identifiable object.
    ///
    /// - Parameter item: A HMCDIdentifiableType instance.
    /// - Returns: A Bool value.
    func compare(against item: HMCDIdentifiableType) -> Bool {
        if let pv1 = self.primaryValue(), let pv2 = item.primaryValue() {
            return pv1 < pv2
        } else {
            return false
        }
    }
}

