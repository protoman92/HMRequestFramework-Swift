//
//  HMVersionUpdateRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// This request object is only used for update requests. The generics represent
/// the type of object being updated.
public struct HMVersionUpdateRequest<VC> {
    fileprivate var original: VC?
    fileprivate var edited: VC?
    fileprivate var strategy: VersionConflict.Strategy
    
    fileprivate init() {
        strategy = .error
    }
    
    public func originalVC() throws -> VC {
        if let original = self.original {
            return original
        } else {
            throw Exception("Original object not available")
        }
    }
    
    public func editedVC() throws -> VC {
        if let edited = self.edited {
            return edited
        } else {
            throw Exception("Edited object not available")
        }
    }
    
    public func conflictStrategy() -> VersionConflict.Strategy {
        return strategy
    }
}

extension HMVersionUpdateRequest: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: Buildable
        
        fileprivate init() {
            request = Buildable()
        }
        
        /// Set the original object.
        ///
        /// - Parameter original: A VC instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(original: VC?) -> Self {
            request.original = original
            return self
        }
        
        /// Set the edited object.
        ///
        /// - Parameter edited: A VC instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(edited: VC?) -> Self {
            request.edited = edited
            return self
        }
        
        /// Set the conflict strategy.
        ///
        /// - Parameter strategy: A Strategy instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(strategy: VersionConflict.Strategy) -> Self {
            request.strategy = strategy
            return self
        }
    }
}

extension HMVersionUpdateRequest.Builder: HMBuilderType {
    public typealias Buildable = HMVersionUpdateRequest<VC>
    
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return self
            .with(original: buildable.original)
            .with(edited: buildable.edited)
            .with(strategy: buildable.strategy)
    }
    
    public func build() -> Buildable {
        return request
    }
}
