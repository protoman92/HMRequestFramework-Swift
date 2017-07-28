//
//  HMCDParsableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Model classes that can be derived from a NSManagedObject subtype should
/// implement this protocol to constrain themselves to specific CD types. This
/// allows us to hide the assocated CD classes, making DB swapping easier in the
/// future.
public protocol HMCDParsableType {
    associatedtype CDClass: NSManagedObject, HMCDConvertibleType
}
