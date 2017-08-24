//
//  HMRequestBuilderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

public protocol HMRequestBuilderType: HMBuilderType {
    associatedtype Buildable: HMRequestType
    typealias MiddlewareFilter = Buildable.MiddlewareFilter
    
    /// Set the value filters.
    ///
    /// - Parameter middlewareFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    func with<S>(middlewareFilters: S) -> Self where
        S: Sequence, S.Iterator.Element == MiddlewareFilter
    
    /// Add a value filter.
    ///
    /// - Parameter middlewareFilter: A filter instance.
    /// - Returns: The current Builder instance.
    func add(middlewareFilter: MiddlewareFilter) -> Self
    
    /// Set the retry count.
    ///
    /// - Parameter retries: An Int value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(retries: Int) -> Self
    
    /// Enable or disable middlewares.
    ///
    /// - Parameter applyMiddlewares: A Bool value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(applyMiddlewares: Bool) -> Self
    
    /// Set the request description.
    ///
    /// - Parameter requestDescription: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(requestDescription: String?) -> Self
}

public extension HMRequestBuilderType {
    
    /// Set the value filters.
    ///
    /// - Parameter middlewareFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    public func with<S>(middlewareFilters: S) -> Self where
        S: Sequence, S.Iterator.Element == MiddlewareFilter.Filter
    {
        return with(middlewareFilters: middlewareFilters.map(HMMiddlewareFilter.init))
    }
    
    /// Add a value filter.
    ///
    /// - Parameter middlewareFilter: A filter instance.
    /// - Returns: The current Builder instance.
    public func add(middlewareFilter: @escaping MiddlewareFilter.Filter) -> Self {
        return add(middlewareFilter: HMMiddlewareFilter(middlewareFilter))
    }
    
    /// Enable middlewares.
    ///
    /// - Returns: The current Builder instance.
    @discardableResult
    public func shouldApplyMiddlewares() -> Self {
        return with(applyMiddlewares: true)
    }
    
    /// Disable middlewares.
    ///
    /// - Returns: The current Builder instance.
    public func shouldNotApplyMiddlewares() -> Self {
        return with(applyMiddlewares: false)
    }
}
