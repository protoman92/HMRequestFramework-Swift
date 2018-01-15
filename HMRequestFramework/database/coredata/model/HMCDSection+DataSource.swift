//
//  HMCDSection+DataSource.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Differentiator

/// Instead of asking HMCDSection to implement AnimatableSectionModelType, we
/// can delegate that to a subtype. This is because the FRC requires the section
/// objects to be of Any generics at first when delegate methods are called.
public struct HMCDAnimatableSection<V: Equatable & IdentifiableType> {
    public let indexTitle: String?
    public let name: String
    public let numberOfObjects: Int
    public let objects: [V]
    
    public init(indexTitle: String?,
                name: String,
                numberOfObjects: Int,
                objects: [V]) {
        self.indexTitle = indexTitle
        self.name = name
        self.numberOfObjects = numberOfObjects
        self.objects = Array(objects)
    }
}

extension HMCDAnimatableSection: HMCDSectionType {}

extension HMCDAnimatableSection: AnimatableSectionModelType {
    public typealias Item = V
    public typealias Identity = String
    
    public var items: [Item] {
        return objects
    }
    
    public var identity: Identity {
        return name
    }
    
    public init(original: HMCDAnimatableSection, items: [Item]) {
        self.init(indexTitle: original.indexTitle,
                  name: original.name,
                  numberOfObjects: original.numberOfObjects,
                  objects: items)
    }
    
    /// Convenience method to map to an animatable section.
    ///
    /// - Parameter f: Mapper function.
    /// - Returns: A HMCDAnimatableSection instance.
    public func mapObjects<V2>(_ f: ([V]) throws -> [V2]?) -> HMCDAnimatableSection<V2> {
        return mapObjects(f, HMCDAnimatableSection<V2>.self)
    }
}

extension HMCDSection {
    
    /// Get a reload section model.
    ///
    /// - Returns: A SectionModel instance.
    public func reloadModel() -> SectionModel<String,V> {
        return SectionModel(model: name, items: objects)
    }
}

extension HMCDSection where V: Equatable, V: IdentifiableType {
    
    /// Get an animatable section model.
    ///
    /// - Returns: A AnimatableSectionModel instance.
    public func animatableModel() -> AnimatableSectionModel<String,V> {
        return AnimatableSectionModel(model: name, items: objects)
    }
    
    public func animatableSection() -> HMCDAnimatableSection<V> {
        return HMCDAnimatableSection(self)
    }
}
