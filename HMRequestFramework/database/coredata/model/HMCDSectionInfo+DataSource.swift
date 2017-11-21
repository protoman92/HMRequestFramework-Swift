//
//  HMCDSection+DataSource.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxDataSources

// We can ask HMCDSection to implement these protocols so that it becomes
// usable with RxDataSources. As a result, it might be easier to use UITableView/
// UICollectionView's rx extensions.
extension HMCDSection: SectionModelType {
    public typealias Item = V
    
    public var items: [Item] {
        return objects
    }
    
    public init(original: HMCDSection<V>, items: [Item]) {
        self.init(indexTitle: original.indexTitle,
                  name: original.name,
                  numberOfObjects: original.numberOfObjects,
                  objects: items)
    }
    
    /// Convenience method to map to a section.
    ///
    /// - Parameter f: Mapper function.
    /// - Returns: A HMCDSection instance.
    public func mapObjects<V2,S>(_ f: ([V]) throws -> S?) -> HMCDSection<V2> where
        S: Sequence, S.Element == V2
    {
        return mapObjects(f, HMCDSection<V2>.self)
    }
}

extension HMCDSection where V: Equatable, V: IdentifiableType {
    
    /// Get an animatable section.
    ///
    /// - Returns: A HMCDAnimatableSection instance.
    public func animated() -> HMCDAnimatableSection<V> {
        return HMCDAnimatableSection<V>(self)
    }
}

/// Instead of asking HMCDSection to implement AnimatableSectionModelType, we
/// can delegate that to a subtype. This is because the FRC requires the section
/// objects to be of Any generics at first when delegate methods are called.
public struct HMCDAnimatableSection<V: Equatable & IdentifiableType> {
    public let indexTitle: String?
    public let name: String
    public let numberOfObjects: Int
    public let objects: [V]
    
    public init<S>(indexTitle: String?,
                   name: String,
                   numberOfObjects: Int,
                   objects: S) where
        S: Sequence, S.Element == V
    {
        self.indexTitle = indexTitle
        self.name = name
        self.numberOfObjects = numberOfObjects
        self.objects = objects.map({$0})
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
    public func mapObjects<V2,S>(_ f: ([V]) throws -> S?) -> HMCDAnimatableSection<V2> where
        V2: Equatable & IdentifiableType, S: Sequence, S.Element == V2
    {
        return mapObjects(f, HMCDAnimatableSection<V2>.self)
    }
}
