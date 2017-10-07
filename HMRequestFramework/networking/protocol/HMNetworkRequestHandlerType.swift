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
public protocol HMNetworkRequestHandlerType: HMRequestHandlerType {
    
    /// Perform a network request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func execute(_ request: Req) throws -> Observable<Try<Data>>
    
    /// Perform a SSE stream request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    func executeSSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>>
}

public extension HMNetworkRequestHandlerType {
    
    /// Perform a network request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - defaultQoS: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func execute<Prev>(_ previous: Try<Prev>,
                              _ generator: @escaping HMRequestGenerator<Prev,Req>,
                              _ defaultQoS: DispatchQoS.QoSClass)
        -> Observable<Try<Data>>
    {
        return execute(previous, generator, execute, defaultQoS)
    }
    
    /// Perform a SSE stream request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - defaultQoS: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func executeSSE<Prev>(_ previous: Try<Prev>,
                                 _ generator: @escaping HMRequestGenerator<Prev,Req>,
                                 _ defaultQoS: DispatchQoS.QoSClass)
        -> Observable<Try<[HMSSEvent<HMSSEData>]>>
    {
        return execute(previous, generator, executeSSE, defaultQoS)
    }
}
