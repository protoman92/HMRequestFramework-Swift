//
//  HMRequestBuilderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

public protocol HMRequestBuilderType: HMBuilderType {
    associatedtype Buildable: HMRequestType
    
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
