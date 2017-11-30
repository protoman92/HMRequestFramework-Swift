//
//  HMNetworkRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to perform network
/// requests and process the results.
public protocol HMNetworkRequestProcessorType: HMNetworkRequestHandlerType {}

public extension HMNetworkRequestProcessorType {
    
    /// Perform a network request and process the result.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func process<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<Data,Res>,
        _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Res>>
    {
        return execute(previous, generator, qos)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
    
    /// Perform a SSE request and process the result.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func processSSE<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<[HMSSEvent<HMSSEData>],Res>,
        _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Res>>
    {
        return executeSSE(previous, generator, qos)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
    
    /// Perform an upload request and process the result.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func processUpload<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<UploadResult,Res>,
        _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Res>>
    {
        return executeUpload(previous, generator, qos)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
}
