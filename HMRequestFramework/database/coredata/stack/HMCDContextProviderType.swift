//
//  HMCDContextProviderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/2/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must provide contexts that can be used
/// by upper layers (for e.g., in a FRC).
public protocol HMCDContextProviderType {
    
    /// This context should be created dynamically to provide disposable scratch pads.
    /// It is the default context for initializing/saving/deleting data objects.
    ///
    /// - Returns: A NSManagedObjectContext instance.
    func disposableObjectContext() -> NSManagedObjectContext
}
