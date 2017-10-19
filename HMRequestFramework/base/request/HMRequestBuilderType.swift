//
//  HMRequestBuilderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

public protocol HMRequestBuilderType: HMBuilderType where Buildable: HMRequestType {
    typealias MiddlewareFilter = Buildable.MiddlewareFilter
    
    /// Set the middleware filters.
    ///
    /// - Parameter mwFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with<S>(mwFilters: S) -> Self where
        S: Sequence, S.Iterator.Element == HMMiddlewareFilter<Buildable>
    
    /// Add a middleware filter.
    ///
    /// - Parameter mwFilter: A filter instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    func add(mwFilter: HMMiddlewareFilter<Buildable>) -> Self
    
    /// Set the retry count.
    ///
    /// - Parameter retries: An Int value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(retries: Int) -> Self
    
    /// Set the retry delay.
    ///
    /// - Parameter retryDelay: A TimeInterval value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(retryDelay: TimeInterval) -> Self
    
    /// Enable or disable middlewares.
    ///
    /// - Parameter applyMiddlewares: A Bool value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(applyMiddlewares: Bool) -> Self
    
    /// Set the request description.
    ///
    /// - Parameter description: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    func with(description: String?) -> Self
}

public extension HMRequestBuilderType {
    
    /// Set the middleware filters.
    ///
    /// - Parameter mwFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with<S>(mwFilters: S) -> Self where
        S: Sequence, S.Iterator.Element == MiddlewareFilter.Filter
    {
        return with(mwFilters: mwFilters.map(HMMiddlewareFilter.init))
    }
    
    /// Add a middleware filter.
    ///
    /// - Parameter mwFilter: A filter instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func add(mwFilter: @escaping MiddlewareFilter.Filter) -> Self {
        return add(mwFilter: HMMiddlewareFilter(mwFilter))
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
    @discardableResult
    public func shouldNotApplyMiddlewares() -> Self {
        return with(applyMiddlewares: false)
    }
}
