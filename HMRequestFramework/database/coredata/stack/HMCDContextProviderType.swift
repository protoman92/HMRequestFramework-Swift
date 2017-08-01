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

public extension HMCDContextProviderType where Self: HMCDObjectConstructorType {
    
    /// Construct a CoreData model object using the disposable context.
    ///
    /// - Parameters cls: A CD class type.
    /// - Returns: A CD instance.
    /// - Throws: Exception if the construction fails.
    public func construct<CD>(_ cls: CD.Type) throws -> CD where
        CD: HMCDRepresentableType
    {
        return try construct(disposableObjectContext(), cls)
    }
    
    /// Construct a CoreData object from a data object, using the disposable
    /// context.
    ///
    /// - Parameter pureObj: A PO instance.
    /// - Returns: A PO.CDClass object.
    /// - Throws: Exception if the construction fails.
    public func construct<PO>(_ pureObj: PO) throws -> PO.CDClass where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return try construct(disposableObjectContext(), pureObj)
    }
    
    /// Convenient method to construct a CoreData model object from a data
    /// class using the disposable context.
    ///
    /// - Parameter pureObj: A PO class.
    /// - Returns: A PO.CDClass object.
    /// - Throws: Exception if the construction fails.
    public func construct<PO>(_ cls: PO.Type) throws -> PO.CDClass
        where PO: HMCDPureObjectType
    {
        return try construct(disposableObjectContext(), cls)
    }
}
