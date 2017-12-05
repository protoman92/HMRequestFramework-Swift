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
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func execute(_ request: Req) throws -> Observable<Try<Data>> {
        return try handler.execute(request)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func executeReachabilitySSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>> {
        return try handler.executeReachabilitySSE(request)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func executeRetrySSE(_ request: Req) throws -> Observable<Try<[HMSSEvent<HMSSEData>]>> {
        return try handler.executeRetrySSE(request)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func executeUpload(_ request: Req) throws -> Observable<Try<UploadResult>> {
        return try handler.executeUpload(request)
    }
}

extension HMNetworkRequestProcessor: HMNetworkRequestProcessorType {}
