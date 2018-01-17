//
//  HMVersionableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must provide version properties that
/// can be updated and compared. This is done so to prevent race conditions when
/// we read/modify/save some objects from/to the DB.
public protocol HMVersionableType {
    
    /// Get the current version.
    ///
    /// - Returns: A String value.
    func currentVersion() -> String?
    
    /// Get the version that is one level up the current one.
    ///
    /// - Returns: A String value.
    func oneVersionHigher() -> String?
    
    /// Check if this object's version is preferable over that of another object.
    /// We do not use Self here because we want to refer to this protocol
    /// directly without Self attachment.
    ///
    /// - Parameter obj: A HMVersionableType instance.
    /// - Returns: A Bool value.
    /// - Throws: Exception if the operation fails.
    func hasPreferableVersion(over obj: HMVersionableType) throws -> Bool
}
