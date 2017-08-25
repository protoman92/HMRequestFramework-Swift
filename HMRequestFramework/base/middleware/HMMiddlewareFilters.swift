//
//  HMMiddlewareFilters.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Utility class for middleware filters.
public final class HMMiddlewareFilters {
    
    /// Get a middleware filter that excludes some middlewares with certain
    /// filterables.
    ///
    /// - Parameter filterables: A Sequence of String.
    /// - Returns: A HMMiddlewareFilter instance.
    public static func excludingFilters<T,S>(_ filterables: S)
        -> HMMiddlewareFilter<T> where
        T: HMMiddlewareFilterableType,
        S: Sequence,
        S.Iterator.Element == T.Filterable
    {
        return HMMiddlewareFilter<T>({!filterables.contains($0.1)})
    }
    
    /// Get a middleware filter that excludes some middlewares with certain
    /// filterables.
    ///
    /// - Parameter filterables: A varargs of String.
    /// - Returns: A HMMiddlewareFilter instance.
    public static func excludingFilters<T>(_ filterables: T.Filterable...)
        -> HMMiddlewareFilter<T> where T: HMMiddlewareFilterableType
    {
        return HMMiddlewareFilters.excludingFilters(filterables)
    }
}
