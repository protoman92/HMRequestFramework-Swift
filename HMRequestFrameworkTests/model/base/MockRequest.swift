//
//  MockRequest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public struct MockRequest {
    fileprivate var retryCount: Int
    fileprivate var middlewaresEnabled: Bool
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        retryCount = 0
        middlewaresEnabled = false
    }
}

extension MockRequest: HMRequestType {
    public func retries() -> Int {
        return retryCount
    }
    
    public func applyMiddlewares() -> Bool {
        return middlewaresEnabled
    }
    
    public func requestDescription() -> String? {
        return rqDescription
    }
}

public extension MockRequest {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: MockRequest
        
        init() {
            request = MockRequest()
        }
        
        @discardableResult
        func with(retries: Int) -> Self {
            request.retryCount = retries
            return self
        }
        
        @discardableResult
        func with(applyMiddlewares: Bool) -> Self {
            request.middlewaresEnabled = applyMiddlewares
            return self
        }
        
        @discardableResult
        func with(requestDescription: String?) -> Self {
            request.rqDescription = requestDescription
            return self
        }
        
        func build() -> MockRequest {
            return request
        }
    }
}
