//
//  HMNetworkRequestHandlerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/22/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle network requests.
public protocol HMNetworkRequestHandlerType: HMRequestHandlerType, HMNetworkRequestAliasType {
    
    /// Perform a network request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func execute(_ request: Req) throws -> Observable<Try<Data>>
    
    /// Open a SSE stream that simply retries whenever it fails to connect to
    /// the source.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func executeRetrySSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>>
    
    /// Open a SSE stream whose lifecycle is tied with reachability.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func executeReachabilitySSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>>
    
    /// Perform an upload request.
    ///
    /// - Parameter req: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func executeUpload(_ req: Req) throws -> Observable<Try<UploadResult>>
}

public extension HMNetworkRequestHandlerType {
    
    /// Perform a network request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func execute<Prev>(_ previous: Try<Prev>,
                              _ generator: @escaping HMRequestGenerator<Prev,Req>,
                              _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Data>>
    {
        return execute(previous, generator, execute, qos)
    }
    
    /// Open a SSE stream whose lifecycle is tied with reachability.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func executeReachabilitySSE<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<[HMSSEvent<HMSSEData>]>>
    {
        return execute(previous, generator, executeReachabilitySSE, qos)
    }
    
    /// Open a SSE stream with infinite retries.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func executeRetrySSE<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<[HMSSEvent<HMSSEData>]>>
    {
        return execute(previous, generator, executeRetrySSE, qos)
    }
    
    /// Perfor an upload request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func executeUpload<Prev>(_ previous: Try<Prev>,
                                    _ generator: @escaping HMRequestGenerator<Prev,Req>,
                                    _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<UploadResult>>
    {
        return execute(previous, generator, executeUpload, qos)
    }
}
