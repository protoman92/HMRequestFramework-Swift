//
//  HMRequestHandlerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to perform some request.
public protocol HMRequestHandlerType {
    associatedtype Req
    
    /// Get the associated middleware manager for requests.
    ///
    /// - Returns: A HMMiddlewareManager instance.
    func requestMiddlewareManager() -> HMMiddlewareManager<Req>
}

public extension HMRequestHandlerType {
    
    /// Create a request based on the result of some upstream request. We also
    /// apply middlewares to the request object.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    func request<Prev>(_ previous: Try<Prev>,
                 _ generator: @escaping HMRequestGenerator<Prev,Req>)
        -> Observable<Try<Req>>
    {
        let manager = requestMiddlewareManager()
        
        return Observable.just(previous)
            .flatMap(generator)
            .flatMap(manager.applyTransformMiddlewares)
            .doOnNext(manager.applySideEffectMiddlewares)
            .catchErrorJustReturn(Try<Req>.failure)
    }
    
    /// Perform a request, based on the result of some previous request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - perform: Execution method.
    /// - Returns: An Observable instance.
    public func execute<Prev,Val>(
        _ previous: Try<Prev>,
        _ generator: @escaping (Try<Prev>) throws -> Observable<Try<Req>>,
        _ perform: @escaping (Req) throws -> Observable<Try<Val>>)
        -> Observable<Try<Val>>
    {
        return request(previous, generator)
            /// If we nest the request like this, even if there are multiple
            /// requests generated (each emitting a Try<Req>), the error
            /// catching would still work correctly.
            .flatMap({$0.rx.get().flatMap(perform)
                .catchErrorJustReturn(Try<Val>.failure)
            })
    }
}
