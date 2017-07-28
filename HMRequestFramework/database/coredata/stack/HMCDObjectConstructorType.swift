//
//  HMCDObjectConstructorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 28/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to construct NSManagedObject
/// without exposing the inner NSManagedObjectContext.
public protocol HMCDObjectConstructorType {
    
    /// Construct a CoreData model object - this is because the context object
    /// is hidden.
    ///
    /// - Parameter cls: A HMCDType class type.
    /// - Returns: A HMCD object.
    /// - Throws: Exception if the construction fails.
    func construct<CD>(_ cls: CD.Type) throws -> CD where CD: HMCDConvertibleType
    
    /// Construct a CoreData object from a data object. With this method, we
    /// do not need to expose the internal NSManagedObjectContext.
    ///
    /// This method is useful when we have two parallel classes - one inheriting
    /// from NSManagedObject, while the other simply contains properties
    /// identical to the former (so that we can avoid hidden pitfalls of
    /// using NSManagedObject directly).
    ///
    /// We can pass the data object to this method, and it will create for
    /// us a NSManagedObject instance with the same properties. We can then
    /// save this to the local DB.
    ///
    /// - Parameter parsable: A HMCDParsableType instance.
    /// - Returns: A HMCDBuildable object.
    /// - Throws: Exception if the construction fails.
    func construct<PS>(_ parsable: PS) throws -> PS.CDClass where
        PS: HMCDParsableType,
        PS.CDClass: HMCDBuildable,
        PS.CDClass.Builder.Base == PS
}

public extension HMCDObjectConstructorType {
    
    /// Convenient method to construct a CoreData model object from a data
    /// class.
    ///
    /// - Parameter cls: A HMCDParsableType class.
    /// - Returns: A HMCD object.
    /// - Throws: Exception if the construction fails.
    public func construct<PS>(_ cls: PS.Type) throws -> PS.CDClass where PS: HMCDParsableType {
        return try construct(cls.CDClass.self)
    }
}
