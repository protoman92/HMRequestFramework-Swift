//
//  HMCDRepresentableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol should be able to construct the
/// data needed to create a CoreData model description.
public protocol HMCDRepresentableType: class {
    
    /// Get the associated attributes.
    ///
    /// - Returns: An Array of NSAttributeDescription.
    static func cdAttributes() throws -> [NSAttributeDescription]?
    
    /// Get the associated entity name.
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if entity name is not available.
    static func entityName() throws -> String
    
    init(_ context: NSManagedObjectContext) throws
}

public extension HMCDRepresentableType {
    
    /// Get the associated entity description.
    ///
    /// - Returns: A NSEntityDescription instance.
    /// - Throws: Exception if the description cannot be created.
    public static func entityDescription() throws -> NSEntityDescription {
        let description = NSEntityDescription()
        description.name = try self.entityName()
        description.managedObjectClassName = NSStringFromClass(Self.self)
        description.properties = try self.cdAttributes() ?? []
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

public extension HMCDRepresentableType where Self: NSManagedObject {
    
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

/// Classes that implement this protocol must be able to construct a CoreData
/// NSManagedObject.
///
/// This protocol is useful when we have 2 parallel classes, one of which
/// inherits from NSManagedObject and the other simply copies the former's
/// properties. The upper layers should only be aware of the latter, so when
/// we wish to save it to CoreData, we will have methods to implicitly convert
/// the pure data class into a CoreData-compatible object.
///
/// The with(base:) method will copy all attributes from the pure data object
/// into the newly constructor CoreData object.
public protocol HMCDBuilderType {
    associatedtype Base: HMCDPureObjectType
    
    func with(base: Base) -> Self
    
    func build() -> Base.CDClass
}

/// Classes that implement this protocol are usually NSManagedObject that
/// has in-built Builders that implement HMCDBuilderType. It should also be
/// convertible to a pure data object.
public protocol HMCDBuildableType {
    associatedtype Builder: HMCDBuilderType
    
    static func builder(_ context: NSManagedObjectContext) throws -> Builder
}
