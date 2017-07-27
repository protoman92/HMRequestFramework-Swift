//
//  HMCDConvertibleType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol should be able to construct the
/// data needed to create a CoreData model description.
public protocol HMCDConvertibleType: class {
    
    /// Get the associated attributes.
    ///
    /// - Returns: An Array of NSAttributeDescription.
    static func cdAttributes() -> [NSAttributeDescription]
    
    /// Get the associated entity name.
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if entity name is not available.
    static func entityName() throws -> String
}

public extension HMCDConvertibleType {
    
    /// Get the associated entity description.
    ///
    /// - Returns: A NSEntityDescription instance.
    /// - Throws: Exception if the description cannot be created.
    public static func entityDescription() throws -> NSEntityDescription {
        let description = NSEntityDescription()
        description.name = try self.entityName()
        description.managedObjectClassName = NSStringFromClass(Self.self)
        description.properties = self.cdAttributes()
        return description
    }
    
    /// Get the associated entity description in a context.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: A NSEntityDescription Optional.
    /// - Throws: Exception if the description is not found.
    public static func entityDescription(in context: NSManagedObjectContext) throws
        -> NSEntityDescription
    {
        let entityName = try self.entityName()
        
        if let description = NSEntityDescription.entity(forEntityName: entityName, in: context) {
            return description
        } else {
            throw Exception("Entity description not available")
        }
    }
}

public extension HMCDConvertibleType where Self: NSManagedObject {
    
    /// Get the associated entity name.
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if entity name is not available.
    public static func entityName() throws -> String {
        let className = NSStringFromClass(classForCoder())
        
        if let name = className.components(separatedBy: ".").last {
            return name
        } else {
            throw Exception("Entity name cannot be nil")
        }
    }
}
