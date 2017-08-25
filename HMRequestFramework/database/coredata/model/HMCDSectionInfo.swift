//
//  HMCDSectionInfo.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this struct instead of NSFetchedResultSectionInfo.
public struct HMCDSectionInfo<V> {
    public let indexTitle: String?
    public let name: String
    public let numberOfObjects: Int
    public let objects: [V]
    
    /// Map the current section info to a different generic.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMCDSectionInfo instance.
    public func map<V2>(_ f: (V) throws -> V2) -> HMCDSectionInfo<V2> {
        return HMCDSectionInfo<V2>(indexTitle: self.indexTitle,
                                   name: self.name,
                                   numberOfObjects: self.numberOfObjects,
                                   objects: self.objects.flatMap({try? f($0)}))
    }
    
    /// Convenience function to cast the current generic to some other type.
    ///
    /// - Parameter cls: The V2 class type.
    /// - Returns: A HMCDSectionInfo instance.
    public func cast<V2>(to cls: V2.Type) -> HMCDSectionInfo<V2> {
        return map({
            if let v2 = $0 as? V2 {
                return v2
            } else {
                throw Exception("Unable to cast \($0) to \(cls)")
            }
        })
    }
}

public extension HMCDSectionInfo where V == Any {
    public init(_ sectionInfo: NSFetchedResultsSectionInfo) {
        indexTitle = sectionInfo.indexTitle
        name = sectionInfo.name
        numberOfObjects = sectionInfo.numberOfObjects
        objects = sectionInfo.objects ?? []
    }
}

public extension HMCDSectionInfo where
    V: HMCDPureObjectType,
    V.CDClass: HMCDPureObjectConvertibleType,
    V.CDClass.PureObject == V
{
    public init(_ sectionInfo: NSFetchedResultsSectionInfo) {
        indexTitle = sectionInfo.indexTitle
        name = sectionInfo.name
        numberOfObjects = sectionInfo.numberOfObjects
        
        objects = sectionInfo.objects?
            .flatMap({$0 as? V.CDClass})
            .map({$0.asPureObject()}) ?? [V]()
    }
}
