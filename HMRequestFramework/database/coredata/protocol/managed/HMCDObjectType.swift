//
//  HMCDObjectType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol should be able to construct the
/// data needed to create a CoreData model description.
public protocol HMCDObjectType: class, HMCDObjectAliasType, HMCDTypealiasType {
    
    /// Get the associated attributes.
    ///
    /// - Returns: An Array of NSAttributeDescription.
    static func cdAttributes() throws -> [NSAttributeDescription]?
    
    /// Get the associated entity name.
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if entity name is not available.
    static func entityName() throws -> String
    
    init(_ context: Context) throws
}

public extension HMCDObjectType {
    
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
    /// - Parameter context: A Context instance.
    /// - Returns: A NSEntityDescription Optional.
    /// - Throws: Exception if the description is not found.
    public static func entityDescription(in context: Context) throws
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

public extension HMCDObjectType where Self: NSManagedObject {
    
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

/// CoreData classes that implement this protocol must be able to transform
/// into a pure object (that does not inherit from NSManagedObject).
public protocol HMCDPureObjectConvertibleType {
    associatedtype PureObject: HMCDPureObjectType
    
    func asPureObject() throws -> PureObject
    
    /// Copy all properties from a pure object. Beware that this method will
    /// mutate the object's internal state, and thus must be used with caution.
    ///
    /// - Parameter object: A PureObject instance.
    func mutateWithPureObject(_ object: PureObject)
}

public extension HMCDPureObjectConvertibleType where
    PureObject.CDClass: NSManagedObject,
    PureObject: HMCDPureObjectBuildableType,
    PureObject.Builder.Buildable.CDClass == Self,
    PureObject.Builder.Buildable == PureObject
{
    /// With the right protocol constraints, we can directly implement this
    /// method by default.
    public func asPureObject() throws -> PureObject {
        /// We need to use this method to fire all possible faults.
        willAccessValue(forKey: nil)
        
        if isFault {
            throw Exception("Object \(self) is faulted")
        } else {
            return PureObject.builder().with(cdObject: self).build()
        }
    }
}
