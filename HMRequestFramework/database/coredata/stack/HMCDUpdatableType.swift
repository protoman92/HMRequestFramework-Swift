//
//  HMCDUpdatableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol should be able to update properties
/// using instances of the same types.
public protocol HMCDUpdatableType {
    
    /// Update inner properties based on those of another object.
    ///
    /// - Parameter obj: A HMCDUpdatableType instance.
    func update(from obj: Self) throws
}

/// Classes that implement this protocol should be able to update its properties
/// using some keys. Strictly for NSManagedObject.
///
/// This protocol implies mutation. Therefore, we should try not to use it
/// as much as possible.
public protocol HMCDKeyValueUpdatableType: HMCDUpdatableType {
    
    /// Get the keys to be used to access inner properties.
    ///
    /// - Returns: An Array of String.
    func updateKeys() -> [String]
    
    /// Get the key-value pairs to be used for an update.
    ///
    /// - Returns: A Dictionary instance.
    func updateDictionary() -> [String : Any?]
    
    /// Update inner properties using a Dictionary.
    ///
    /// - Parameter dict: A Dictionary instance.
    func update(with dict: [String : Any?]) throws
}

public extension HMCDKeyValueUpdatableType {
    
    /// Update inner properties using another HMCDUpdatableType. This method
    /// assumes that this object does not need to validate the incoming updates.
    ///
    /// - Parameter obj: A HMCDKeyValueUpdatableType instance.
    public func update(from obj: Self) throws {
        try update(with: obj.updateDictionary())
    }
}

public extension HMCDKeyValueUpdatableType where Self: NSManagedObject {
    public func updateDictionary() -> [String : Any?] {
        var dict: [String : Any?] = [:]
        let keys = updateKeys()
        
        for key in keys {
            dict.updateValue(value(forKey: key), forKey: key)
        }
        
        return dict
    }
    
    public func update(with dict: [String : Any?]) throws {
        for (key, value) in dict {
            setValue(value, forKey: key)
        }
    }
}
