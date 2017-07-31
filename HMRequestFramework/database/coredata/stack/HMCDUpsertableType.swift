//
//  HMCDUpsertableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 31/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol should extend from NSManagedObject
/// and can be upserted.
///
/// This protocol also extends HMJSONConvertible so that we can dynamically
/// set the properties on a NSManagedObject that already exists within the
/// DB.
public protocol HMCDUpsertableType: HMUpsertableType, HMJSONConvertibleType where
    Self: NSManagedObject {}

/// Instead of inheriting from NSManagedObject, inherit from the class to
/// access upsert-related properties.
public class HMCDUpsertableObject: NSManagedObject {}

extension HMCDUpsertableObject: HMCDUpsertableType {
    public func primaryKey() -> String {
        fatalError("Must override this")
    }
    
    public func primaryValue() -> String {
        fatalError("Must override this")
    }
    
    public func toJSON() -> [String : Any] {
        fatalError("Must override this")
    }
}
