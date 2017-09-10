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
    
    public init(requestMiddlewareManager: HMFilterMiddlewareManager<Req>) {
        rqmManager = requestMiddlewareManager
    }
}

extension RequestHandler: HMRequestHandlerType {
    public typealias Req = MockRequest
    
    public func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>? {
        return rqmManager
    }
}
