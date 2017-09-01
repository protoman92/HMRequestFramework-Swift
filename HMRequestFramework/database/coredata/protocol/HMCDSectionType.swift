//
//  HMCDSectionType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must be able to provide section
/// information to be populated in a list view.
public protocol HMCDSectionType {
    associatedtype V
    
    var indexTitle: String? { get }
    var name: String { get }
    var numberOfObjects: Int { get }
    var objects: [V] { get }
    
    init<S>(indexTitle: String?,
            name: String,
            numberOfObjects: Int,
            objects: S) where
        S: Sequence, S.Iterator.Element == V
}

public extension HMCDSectionType {
    public init<ST>(_ type: ST) where ST: HMCDSectionType, ST.V == V {
        self.init(indexTitle: type.indexTitle,
                  name: type.name,
                  numberOfObjects: type.numberOfObjects,
                  objects: type.objects)
    }
}
