//
//  HMValueFilterableType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must define some filters to filter out
/// instances of some type. This could be especially useful in the case of
/// middlewares, whereby we want to disable certain middlewares for some requests.
///
/// For example, a request object may implement this protocol with a String
/// Filterable. When middlewares are applied, they will be filtered out based
/// on the filters defined by said request, since each middleware is associated
/// with a name.
///
/// If we do not want certain middlewares to apply to a request, we can add a
/// filter as such: HMValueFilter({$0.1 != middlewareName}). These middlewares
/// will be omitted from the application.
public protocol HMValueFilterableType {
    associatedtype Filterable
    
    /// Get an Array of filters of Self type.
    ///
    /// - Returns: An Array of filters.
    func valueFilters() -> [HMValueFilter<Self>]
}
