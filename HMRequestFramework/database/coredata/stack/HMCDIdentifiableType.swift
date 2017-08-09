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
public protocol HMCDIdentifiableType: HMIdentifiableType {}

/// Instead of inheriting from NSManagedObject, inherit from the class to
/// access non-ObjectID identifiers.
open class HMCDIdentifiableObject: NSManagedObject {}

extension HMCDIdentifiableObject: HMCDIdentifiableType {
    open func primaryKey() -> String {
        fatalError("Must override this")
    }
    
    open func primaryValue() -> String {
        fatalError("Must override this")
    }
}
