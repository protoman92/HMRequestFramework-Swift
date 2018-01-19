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
        fileprivate var editedRepr: String?
        fileprivate var originalRepr: String?
        fileprivate var existingVer: String?
        fileprivate var conflictVer: String?
        
        public func editedObjectRepresentation() -> String? {
            return editedRepr
        }
        
        public func originalObjectRepresentation() -> String? {
            return originalRepr
        }
        
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

extension VersionConflict.Exception: LocalizedError {
    public var cause: Error {
        return self
    }
    
    public var localizedDescription: String {
        return errorDescription ?? ""
    }
    
    public var errorDescription: String? {
        return originalRepr.zipWith(editedRepr, {($0, $1)})
            .zipWith(existingVer, {($0.0, $0.1, $1)})
            .zipWith(conflictVer, {($0.0, $0.1, $0.2, $1)})
            .map({""
                + "Conflict encountered while updating original object \"\($0)\" "
                + "using edited object \"\($1)\".\n"
                + "Existing version: \($2)\n"
                + "Conflict version: \($3)."})
            .getOrElse("Unable to get error message")
    }
}

extension VersionConflict.Exception: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var exception: VersionConflict.Exception
        
        fileprivate init() {
            exception = VersionConflict.Exception()
        }
        
        /// Set the edited object representation.
        ///
        /// - Parameter editedRepr: A String value.
        /// - Returns: The current Builder instance.
        public func with(editedRepr: String?) -> Self {
            exception.editedRepr = editedRepr
            return self
        }
        
        /// Set the original object representation.
        ///
        /// - Parameter originalRepr: A String value.
        /// - Returns: The current Builder instance.
        public func with(originalRepr: String?) -> Self {
            exception.originalRepr = originalRepr
            return self
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
                .with(editedRepr: buildable.editedRepr)
                .with(originalRepr: buildable.originalRepr)
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
