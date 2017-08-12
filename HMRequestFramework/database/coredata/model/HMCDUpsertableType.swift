//
//  HMCDUpsertableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/11/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must define certain properties to be
/// used in an upsert operation.
public protocol HMCDUpsertableType:
    NSFetchRequestResult,           // Type can be retained in a fetch ops.
    HMCDIdentifiableType,           // Identifiable in DB.
    HMCDKeyValueUpdatableType {}    // Updatable using key-value pairs.
