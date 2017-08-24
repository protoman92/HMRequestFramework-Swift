//
//  HMRequestBuilderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

public protocol HMRequestBuilderType: HMBuilderType {
    associatedtype Buildable: HMRequestType
    
    /// Set the value filters.
    ///
    /// - Parameter valueFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    func with<S>(valueFilters: S) -> Self where
        S: Sequence, S.Iterator.Element == HMValueFilter<Buildable>
    
    /// Add a value filter.
    ///
    /// - Parameter valueFilter: A filter instance.
    /// - Returns: The current Builder instance.
    func add(valueFilter: Buildable.MiddlewareFilter) -> Self
    
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
    /// - Parameter valueFilters: A Sequence of filters.
    /// - Returns: The current Builder instance.
    public func with<S>(valueFilters: S) -> Self where
        S: Sequence,
        S.Iterator.Element == (Buildable, Buildable.Filterable) throws -> Bool
    {
        return with(valueFilters: valueFilters.map(HMValueFilter.init))
    }
    
    /// Add a value filter.
    ///
    /// - Parameter valueFilter: A filter instance.
    /// - Returns: The current Builder instance.
    public func add(valueFilter: @escaping (Buildable, Buildable.Filterable) throws -> Bool) -> Self {
        return add(valueFilter: HMValueFilter(valueFilter))
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
