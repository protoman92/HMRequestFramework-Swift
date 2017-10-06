//
//  HMRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 6/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Base request type that can be used for HMRequestHandler.
public protocol HMRequestType: HMMiddlewareFilterableType {
    typealias MiddlewareFilter = HMMiddlewareFilter<Self>

    /// Specify how many times a request should be retries.
    ///
    /// - Returns: An Int value.
    func retries() -> Int
    
    /// Specify how long two consecutive retries are from each other.
    ///
    /// - Returns: A TimeInterval value.
    func retryDelay() -> TimeInterval
    
    /// Indicate whether middlewares should apply to this request. This is
    /// useful for when a request is being performed for a middleware itself.
    /// Without this flag, we could encounter an infinite loop.
    ///
    /// - Returns: A Bool value.
    func applyMiddlewares() -> Bool
    
    /// Get the request description. We use this for logging purposes.
    ///
    /// - Returns: A String value.
    func requestDescription() -> String?
    
    /// Get the default QoS to push events.
    ///
    /// - Returns: A QoSClass instance.
    func defaultQoS() -> DispatchQoS.QoSClass
}
