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
    associatedtype Req: HMRequestType
    
    /// Get the associated middleware manager for requests.
    ///
    /// - Returns: A HMMiddlewareManager instance.
    func requestMiddlewareManager() -> HMMiddlewareManager<Req>?
}

public extension HMRequestHandlerType {
    
    /// Create a request based on the result of some upstream request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: A HMRequestGenerator instance.
    /// - Returns: An Observable instance.
    func request<Prev>(_ previous: Try<Prev>,
                       _ generator: @escaping HMRequestGenerator<Prev,Req>)
        -> Observable<Try<Req>>
    {
        return Observable.just(previous)
            .flatMap(generator)
            .catchErrorJustReturn(Try<Req>.failure)
    }
    
    /// Perform a request, based on the result of some previous request. We
    /// also apply middlewares to the request object.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: A HMRequestGenerator instance.
    ///   - perform: A HMRequestPerformer instance.
    /// - Returns: An Observable instance.
    public func execute<Prev,Val>(_ previous: Try<Prev>,
                                  _ generator: @escaping HMRequestGenerator<Prev,Req>,
                                  _ perform: @escaping HMRequestPerformer<Req,Val>)
        -> Observable<Try<Val>>
    {
        return request(previous, generator)
            /// If we nest the request like this, even if there are multiple
            /// requests generated (each emitting a Try<Req>), the error
            /// catching would still work correctly.
            .flatMap({$0.rx.get()
                .flatMap(self.applyRequestMiddlewares)
                .flatMap(perform)
                .catchErrorJustReturn(Try<Val>.failure)
            })
    }
    
    /// Apply request middlewares if necessary.
    ///
    /// - Parameter request: A HMRequestType instance.
    /// - Returns: An Observable instance.
    func applyRequestMiddlewares(_ request: Req) -> Observable<Req> {
        if let manager = requestMiddlewareManager(), request.applyMiddlewares() {
            return manager.applyTransformMiddlewares(request)
                .doOnNext(manager.applySideEffectMiddlewares)
        } else {
            return Observable.just(request)
        }
    }
}
