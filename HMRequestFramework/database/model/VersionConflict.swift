//
//  VersionConflictStrategy.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// This class contains convenient enums to deal with version conflicts.
public final class VersionConflict {
    public struct Exception {
        fileprivate var existingVer: String?
        fileprivate var conflictVer: String?
        
        public func existingVersion() -> String? {
            return existingVer
        }
        
        public func conflictVersion() -> String? {
            return conflictVer
        }
    }
    
    /// Specify the strategy to apply when a version conflict is encountered.
    ///
    /// - error: Throw an Error.
    /// - merge: Merge the objects based on some merging strategy.
    /// - overwrite: Ignore and continue the update.
    /// - takePreferable: Take the ones with preferable versions.
    public enum Strategy {
        case error
        case merge(HMVersionableType.MergeFn?)
        case overwrite
        case takePreferable
        
        public func isError() -> Bool {
            switch self {
            case .error: return true
            default: return false
            }
        }
        
        public func isMerge() -> Bool {
            switch self {
            case .merge: return true
            default: return false
            }
        }
        
        public func isOverwrite() -> Bool {
            switch self {
            case .overwrite: return true
            default: return false
            }
        }
        
        public func isTakePreferable() -> Bool {
            switch self {
            case .takePreferable: return true
            default: return false
            }
        }
    }
    
    private init() {}
}

extension VersionConflict.Exception: Error {}

extension VersionConflict.Exception: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var exception: VersionConflict.Exception
        
        fileprivate init() {
            exception = VersionConflict.Exception()
        }
        
        /// Set the existing version.
        ///
        /// - Parameter existingVersion: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(existingVersion: String?) -> Self {
            exception.existingVer = existingVersion
            return self
        }
        
        /// Set the conflict version.
        ///
        /// - Parameter conflictVersion: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(conflictVersion: String?) -> Self {
            exception.conflictVer = conflictVersion
            return self
        }
    }
}

extension VersionConflict.Exception.Builder: HMBuilderType {
    public typealias Buildable = VersionConflict.Exception
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(existingVersion: buildable.existingVer)
                .with(conflictVersion: buildable.conflictVer)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return exception
    }
}
