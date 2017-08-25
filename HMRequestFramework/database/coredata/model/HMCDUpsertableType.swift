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
    HMCDIdentifiableType,               // Identifiable in DB.
    HMCDKeyValueRepresentableType {}    // Representable as key-value pairs.

