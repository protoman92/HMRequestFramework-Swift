//
//  RequestHandler.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public struct RequestHandler {
    let rqmManager: HMFilterMiddlewareManager<Req>
    let errManager: HMGlobalMiddlewareManager<HMErrorHolder>
    
    public init(rqMiddlewareManager: HMFilterMiddlewareManager<Req>,
                errMiddlewareManager: HMGlobalMiddlewareManager<HMErrorHolder>) {
        rqmManager = rqMiddlewareManager
        errManager = errMiddlewareManager
    }
}

extension RequestHandler: HMRequestHandlerType {
    public typealias Req = MockRequest
    
    public func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>? {
        return rqmManager
    }
    
    public func errorMiddlewareManager() -> HMFilterMiddlewareManager<HMErrorHolder>? {
        return errManager
    }
}
