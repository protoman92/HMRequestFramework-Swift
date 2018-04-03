//
//  HMRequestHandlerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftFP
import SwiftUtilities

/// Classes that implement this protocol must be able to perform some request.
public protocol HMRequestHandlerType {
    associatedtype Req: HMRequestType
    
    /// Get the associated middleware manager for requests.
    ///
    /// - Returns: A HMFilterMiddlewareManager instance.
    func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>?
    
    /// Get the associated middleware manager for errors.
    ///
    /// - Returns: A HMGlobalMiddlewareManager instance.
    func errorMiddlewareManager() -> HMGlobalMiddlewareManager<HMErrorHolder>?
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
    ///   - qos: A QoSClass instance to perform work with.
    /// - Returns: An Observable instance.
    public func execute<Prev,Val>(_ previous: Try<Prev>,
                                  _ generator: @escaping HMRequestGenerator<Prev,Req>,
                                  _ perform: @escaping HMRequestPerformer<Req,Val>,
                                  _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Val>>
    {
        return request(previous, generator)
            
            /// If we nest the request like this, even if there are multiple
            /// requests generated (each emitting a Try<Req>), the error
            /// catching would still work correctly.
            .flatMap({(req: Try<Req>) in Observable.just(req)
                .map({try $0.getOrThrow()})
                .flatMap(self.applyRequestMiddlewares)
                .flatMap(perform)
                
                // We need to force get here to catch and transform errors.
                .map({try $0.getOrThrow()})
                .map(Try.success)
                .catchError({self.applyErrorMiddlewares(req, $0)})
                .catchErrorJustReturn(Try.failure)
            })
            .subscribeOnConcurrent(qos: qos)
    }
    
    /// Apply request middlewares if necessary.
    ///
    /// - Parameter request: A HMRequestType instance.
    /// - Returns: An Observable instance.
    func applyRequestMiddlewares(_ request: Req) -> Observable<Req> {
        Preconditions.checkNotRunningOnMainThread(request)
        
        if let manager = requestMiddlewareManager(), request.applyMiddlewares() {
            return manager.applyTransformMiddlewares(request)
                .doOnNext(manager.applySideEffectMiddlewares)
        } else {
            return Observable.just(request)
        }
    }
    
    /// Apply error middlewares if necessary.
    ///
    /// - Parameters:
    ///   - request: A Try Req instance.
    ///   - error: An Error instance.
    /// - Returns: An Observable instance.
    func applyErrorMiddlewares<Val>(_ request: Try<Req>, _ error: Error)
        -> Observable<Try<Val>>
    {
        Preconditions.checkNotRunningOnMainThread(request)
        
        if let manager = errorMiddlewareManager() {
            let rqDescription = request.value?.requestDescription()
            
            let holder: HMErrorHolder
            
            if let prevHolder = error as? HMErrorHolder {
                holder = HMErrorHolder.builder()
                    .with(buildable: prevHolder)
                    .with(requestDescription: rqDescription)
                    .build()
            } else {
                holder = HMErrorHolder.builder()
                    .with(error: error)
                    .with(requestDescription: rqDescription)
                    .build()
            }
            
            return manager.applyTransformMiddlewares(holder)
                .doOnNext(manager.applySideEffectMiddlewares)
                .map({Try.failure($0)})
        } else {
            return Observable.just(Try.failure(error))
        }
    }
}
