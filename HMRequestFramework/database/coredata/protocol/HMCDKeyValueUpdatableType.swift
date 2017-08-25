//
//  HMCDKeyValueUpdatableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol should be able to update its properties
/// using some keys. Strictly for NSManagedObject.
///
/// This protocol implies mutation. Therefore, we should try not to use it
/// as much as possible.
public protocol HMCDKeyValueUpdatableType: HMCDKeyValueRepresentableType {
    
    /// Update inner properties using a Dictionary.
    ///
    /// - Parameter dict: A Dictionary instance.
    func update(with dict: [String : Any?]) throws
}

public extension HMCDKeyValueUpdatableType {
    
    /// Update inner properties using another HMCDKeyValueUpdatableType. This method
    /// assumes that this object does not need to validate the incoming updates.
    ///
    /// - Parameter obj: A HMCDKeyValueUpdatableType instance.
    public func update(from obj: HMCDKeyValueUpdatableType) throws {
        try update(with: obj.updateDictionary())
    }
}

public extension HMCDKeyValueUpdatableType where Self: NSObject {
    
    /// Update the current object's properties with NSObject methods.
    ///
    /// - Parameter dict: A Dictionary instance.
    /// - Throws: Exception if the update fails.
    public func update(with dict: [String : Any?]) throws {
        for (key, value) in dict {
            setValue(value, forKey: key)
        }
    }
}
