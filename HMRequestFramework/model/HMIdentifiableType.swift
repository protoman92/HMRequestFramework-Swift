//
//  HMUpsertableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 31/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must provide the required information
/// to identify its instances in a DB.
public protocol HMIdentifiableType {
    
    /// Get a uniquely identifiable key to perform database lookup for existing
    /// records.
    ///
    /// - Returns: A String value.
    func primaryKey() -> String
    
    /// Get the corresponding value for the primary key.
    ///
    /// - Returns: A String value.
    func primaryValue() -> String
}
