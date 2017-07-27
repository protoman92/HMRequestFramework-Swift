//
//  HMCDType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 27/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// CoreData model classes should implement this protocol.
public protocol HMCDType {
    init(_ context: NSManagedObjectContext) throws
}
