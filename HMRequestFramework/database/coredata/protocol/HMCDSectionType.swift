//
//  HMCDSectionType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol must be able to provide section
/// information to be populated in a list view.
public protocol HMCDSectionType {
    associatedtype V
    
    var indexTitle: String? { get }
    var name: String { get }
    var numberOfObjects: Int { get }
    var objects: [V] { get }
    
    init(indexTitle: String?,
         name: String,
         numberOfObjects: Int,
         objects: [V])
}

public extension HMCDSectionType {
    
    /// Get an empty section object.
    ///
    /// - Returns: A Self instance.
    static func empty() -> Self {
        return Self.init(indexTitle: nil, name: "", objects: [])
    }
    
    public init(indexTitle: String?, name: String, objects: [V]) {
        self.init(indexTitle: indexTitle,
                  name: name,
                  numberOfObjects: objects.count,
                  objects: objects)
    }
    
    public init<ST>(_ type: ST) where ST: HMCDSectionType, ST.V == V {
        self.init(indexTitle: type.indexTitle,
                  name: type.name,
                  numberOfObjects: type.numberOfObjects,
                  objects: type.objects)
    }
    
    public init<ST>(_ type: ST, _ objectLimit: Int) where ST: HMCDSectionType, ST.V == V {
        let objects = type.objects
        let slicedCount = Swift.min(objectLimit, objects.count)
        let slicedObjects = objects[0..<slicedCount].map({$0})
        
        self.init(indexTitle: type.indexTitle,
                  name: type.name,
                  numberOfObjects: slicedCount,
                  objects: slicedObjects)
    }
    
    public func withObjectLimit(_ limit: Int) -> Self {
        return Self.init(self, limit)
    }
    
    
    /// Map the current objects to a different type using a mapper function.
    ///
    /// - Parameters:
    ///   - f: Mapper function.
    ///   - sectionCls: The section class type resulting from the conversion.
    /// - Returns: A SC instance.
    public func mapObjects<V2,SC>(_ f: (([V]) throws -> [V2]?),
                                  _ sectionCls: SC.Type) -> SC where
        SC: HMCDSectionType, SC.V == V2
    {
        let newObjects = ((try? f(objects)?.map({$0})) ?? []) ?? []
        let numberOfObjects = newObjects.count
        
        return SC.init(indexTitle: indexTitle,
                       name: name,
                       numberOfObjects: numberOfObjects,
                       objects: newObjects)
    }
}
