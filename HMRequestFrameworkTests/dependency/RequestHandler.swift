//
//  RequestHandler.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public struct RequestHandler {
    let rqMiddlewareManager: HMMiddlewareManager<Req>
    
    public init(requestMiddlewareManager: HMMiddlewareManager<Req>) {
        rqMiddlewareManager = requestMiddlewareManager
    }
}

extension RequestHandler: HMRequestHandlerType {
    public typealias Req = MockRequest
    
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req> {
        return rqMiddlewareManager
    }
}
