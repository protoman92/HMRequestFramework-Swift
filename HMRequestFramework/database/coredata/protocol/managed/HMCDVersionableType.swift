//
//  HMCDVersionableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Similar to HMVersionableType, customized for CoreData. They should be
/// identifiable without ObjectID (e.g. by having some other combination of
/// primary key/value), and also support updating inner values and version.
/// However, we should avoid such mutations as much as we can.
public protocol HMCDVersionableType:
    HMVersionableType,              // Minimally versionable.
    HMCDUpsertableType,             // Upsertable in DB.
    HMCDKeyValueUpdatableType,      // Updatable with key-value pairs.
    HMCDVersionUpdatableType {}     // Updatable w.r.t version.

/// Classes that implement this protocol must be able to update version. Since
/// this protocol implies mutation, we should avoid using it as much as possible.
public protocol HMCDVersionUpdatableType {
    
    /// Update the version by mutating property.
    ///
    /// - Parameter version: A String value.
    func updateVersion(_ version: String?) throws
}
