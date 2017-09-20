//
//  HMResult.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// Use this class to represent the result of some operation that is applied
/// to multiple items (e.g. in an Array), for which the result of each application
/// could be relevant to downstream flow.
public struct HMResult<Val> {
    public static func just(_ obj: Val) -> HMResult<Val> {
        return HMResult<Val>.builder().with(object: obj).build()
    }
    
    public static func just(_ error: Error) -> HMResult<Val> {
        return HMResult<Val>.builder().with(error: error).build()
    }
    
    /// Convert a Try to a HMResult.
    ///
    /// - Parameter tryInstance: A Try instance.
    /// - Returns: A HMResult instance.
    public static func from(_ tryInstance: Try<Val>) -> HMResult<Val> {
        switch tryInstance {
        case .success(let result):
            return HMResult<Val>.just(result)
            
        case .failure(let e):
            return HMResult<Val>.just(e)
        }
    }
    
    /// Unwrap a Try that contains a HMResult.
    ///
    /// - Parameter wrapped: A Try instance.
    /// - Returns: A HMResult instance.
    public static func unwrap(_ wrapped: Try<HMResult<Val>>) -> HMResult<Val> {
        switch wrapped {
        case .success(let result):
            return result
            
        case .failure(let e):
            return HMResult<Val>.just(e)
        }
    }
    
    fileprivate var object: Val?
    fileprivate var error: Error?
    
    fileprivate init() {}
    
    public func appliedObject() -> Val? {
        return object
    }
    
    public func operationError() -> Error? {
        return error
    }
}

public extension HMResult {
    public func isSuccess() -> Bool {
        return error == nil
    }
    
    public func isFailure() -> Bool {
        return !isSuccess()
    }
}

extension HMResult: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var result: HMResult
        
        fileprivate init() {
            result = HMResult()
        }
        
        /// Set the object to which the operation was applied.
        ///
        /// - Parameter object: A Val instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(object: Val?) -> Self {
            result.object = object
            return self
        }
        
        /// Set the operation Error.
        ///
        /// - Parameter error: An Error instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(error: Error?) -> Self {
            result.error = error
            return self
        }
    }
}

extension HMResult.Builder: HMBuilderType {
    public typealias Buildable = HMResult<Val>
    
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(object: buildable.object)
                .with(error: buildable.error)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return result
    }
}
