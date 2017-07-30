//
//  HMBuildableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must declare a Builder class to
/// construct instances of said classes.
public protocol HMBuildableType {
    associatedtype Builder: HMBuilderType
    
    static func builder() -> Builder
}

/// Builders should implement this protocol.
public protocol HMBuilderType {
    associatedtype Buildable: HMBuildableType
    
    func with(buildable: Buildable) -> Self
    
    func build() -> Buildable
}

public extension HMBuildableType where Self == Builder.Buildable {

    /// Instead of mutating properties here, we create a new Builder and copy
    /// all properties to the new Buildable instance.
    ///
    /// - Returns: A Builder instance.
    public func cloneBuilder() -> Builder {
        return Self.builder().with(buildable: self)
    }
}

