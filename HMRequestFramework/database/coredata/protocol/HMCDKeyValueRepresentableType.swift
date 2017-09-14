//
//  HMCDKeyValueRepresentableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to produce a Dictionary
/// of their instance properties.
public protocol HMCDKeyValueRepresentableType {
    
    /// Get the keys to be used to access inner properties.
    ///
    /// - Returns: An Array of String.
    func updateKeys() -> [String]
    
    /// Get the key-value pairs to be used for an update.
    ///
    /// - Returns: A Dictionary instance.
    func updateDictionary() -> [String : Any?]
}

public extension HMCDKeyValueRepresentableType where Self: NSObject {
    
    /// Get the properties dictionary using NSObject methods.
    ///
    /// - Returns: A Dictionary instance.
    public func updateDictionary() -> [String : Any?] {
        let keys = updateKeys()
        var properties: [String : Any?] = [:]
        
        for key in keys {
            properties.updateValue(value(forKey: key), forKey: key)
        }
        
        return properties
    }
}

/// If a NSManagedObject conforms to this protocol, it automatically has
/// updateKeys() implemented.
public extension HMCDKeyValueRepresentableType where Self: NSManagedObject {
    public func updateKeys() -> [String] {
        return entity.attributesByName.keys.map({$0})
    }
}
