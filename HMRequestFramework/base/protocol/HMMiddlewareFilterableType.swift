//
//  HMMiddlewareFilterableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must define some filters to filter out
/// middlewares.
///
/// For example, a request object may implement this protocol with a String
/// Filterable. When middlewares are applied, they will be filtered out based
/// on the filters defined by said request, since each middleware is associated
/// with a name.
///
/// If we do not want certain middlewares to apply to a request, we can add a
/// filter as such: HMMiddlewareFilter({$0.1 != middlewareName}). These middlewares
/// will be omitted from the application.
public protocol HMMiddlewareFilterableType {
    associatedtype Filterable: Equatable
    
    /// Get an Array of filters of Self type.
    ///
    /// - Returns: An Array of filters.
    func middlewareFilters() -> [HMMiddlewareFilter<Self>]
}

/// Use this protocol to disable middleware filters. All middlewares that
/// implement this protocol apply to all targets.
public protocol HMMiddlewareGlobalApplicableType: HMMiddlewareFilterableType {}

public extension HMMiddlewareGlobalApplicableType {
    public typealias Filterable = String
    
    /// Get an Array of filters of Self type.
    ///
    /// - Returns: An Array of filters.
    public func middlewareFilters() -> [HMMiddlewareFilter<Self>] {
        return []
    }
}
