//
//  HMErrorHolder.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// Classes that implement this protocol must be able to substitute errors with
/// their instances.
public protocol HMErrorHolderType: LocalizedError {
    func requestDescription() -> String?
    
    func error() throws -> Error
}

/// Use this struct to comply with global middleware applicable.
public struct HMErrorHolder {
    fileprivate var rqDescription: String?
    fileprivate var originalError: Error?
}

extension HMErrorHolder: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var holder: HMErrorHolder
        
        fileprivate init() {
            holder = HMErrorHolder()
        }
        
        /// Set the original error.
        ///
        /// - Parameter error: An Error instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(error: Error?) -> Self {
            holder.originalError = error
            return self
        }
        
        /// Transform the error if it is available.
        ///
        /// - Parameter errorTransform: Transformer function.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(errorTransform: (Error) throws -> Error?) -> Self {
            if let e1 = try? holder.error(), let e2 = try? errorTransform(e1) {
                return with(error: e2)
            } else {
                return self
            }
        }
        
        /// Transform the error if it is available.
        ///
        /// - Parameter errorTransform: Transformer function.
        /// - Returns: The current Builder instance.
        public func with<E>(errorTransform: (E) throws -> Error?) -> Self where E: Error {
            return with(errorTransform: {
                if let error = $0 as? E {
                    return try errorTransform(error)
                } else {
                    return nil
                }
            })
        }
        
        /// Transform the error if it is available.
        ///
        /// - Parameters:
        ///   - cls: The E class type.
        ///   - errorTransformer: Transformer function.
        /// - Returns: The current Builder instance.
        public func with<E>(_ cls: E.Type, errorTransform: (E) throws -> Error?)
            -> Self where E: Error
        {
            return with(errorTransform: errorTransform)
        }
        
        /// Set the request description.
        ///
        /// - Parameter requestDescription: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(requestDescription: String?) -> Self {
            holder.rqDescription = requestDescription
            return self
        }
    }
}

extension HMErrorHolder: HMErrorHolderType {
    public var errorDescription: String? {
        return (try? error().localizedDescription) ?? ""
    }
    
    public func error() throws -> Error {
        if let error = originalError {
            return error
        } else {
            throw Exception("Original error cannot be nil")
        }
    }
    
    public func requestDescription() -> String? {
        return rqDescription
    }
}

extension HMErrorHolder: HMProtocolConvertibleType {
    public typealias PTCType = HMErrorHolderType
    
    public func asProtocol() -> PTCType {
        return self
    }
}

extension HMErrorHolder.Builder: HMProtocolConvertibleBuilderType {
    public typealias Buildable = HMErrorHolder
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter generic: A Buildable.PTCType instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(generic: Buildable.PTCType?) -> Self {
        if let generic = generic {
            return self
                .with(error: try? generic.error())
                .with(requestDescription: generic.requestDescription())
        } else {
            return self
        }
    }

    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        return with(generic: buildable)
    }
    
    public func build() -> Buildable {
        return holder
    }
}

extension HMErrorHolder: Error {}

extension HMErrorHolder: HMMiddlewareGlobalApplicableType {
    public typealias Filterable = String
}
