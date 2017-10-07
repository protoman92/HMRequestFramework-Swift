//
//  HMNetworkRequestProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxSwift
import SwiftUtilities

/// This class offer decorated processing over a HMNetworkRequestHandler.
public struct HMNetworkRequestProcessor {
    
    /// This variable has internal access just for testing purposes.
    public let handler: HMNetworkRequestHandler
    
    public init(handler: HMNetworkRequestHandler) {
        self.handler = handler
    }
}

extension HMNetworkRequestProcessor: HMNetworkRequestProcessorType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    ///   - defaultQoS: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func process<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequest>,
        _ processor: @escaping HMResultProcessor<Data,Res>,
        _ defaultQoS: DispatchQoS.QoSClass)
        -> Observable<Try<Res>>
    {
        return handler.execute(previous, generator, defaultQoS)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
}

extension HMNetworkRequestProcessor: HMNetworkRequestHandlerType {
    public typealias Req = HMNetworkRequestHandler.Req
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMFilterMiddlewareManager instance.
    public func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>? {
        return handler.requestMiddlewareManager()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMFilterMiddlewareManager instance.
    public func errorMiddlewareManager() -> HMFilterMiddlewareManager<HMErrorHolder>? {
        return handler.errorMiddlewareManager()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    public func execute(_ request: Req) throws -> Observable<Try<Data>> {
        return try handler.execute(request)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    public func executeSSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>> {
        return try handler.executeSSE(request)
    }
}
