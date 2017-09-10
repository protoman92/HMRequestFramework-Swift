//
//  HMNetworkRequestProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

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
    /// - Returns: An Observable instance.
    public func process<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequest>,
        _ processor: @escaping HMResultProcessor<Data,Res>)
        -> Observable<Try<Res>>
    {
        return handler.execute(previous, generator)
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
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    public func execute<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>)
        -> Observable<Try<Data>>
    {
        return handler.execute(previous, generator)
    }
}
