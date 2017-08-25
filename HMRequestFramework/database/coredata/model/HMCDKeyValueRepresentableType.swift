//
//  HMCDKeyValueRepresentableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

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
        var dict: [String : Any?] = [:]
        let keys = updateKeys()
        
        for key in keys {
            dict.updateValue(value(forKey: key), forKey: key)
        }
        
        return dict
    }
}
