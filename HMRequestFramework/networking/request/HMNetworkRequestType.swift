//
//  HMNetworkRequestType.swift
//  HMRequestFramework-iOS
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Instead of having different request subtypes, we put all possible 
/// requirements here, and differentiate among multiple types of requests 
/// using the associated HttpMethod.
public protocol HMNetworkRequestType: HMRequestType, HMNetworkResourceType {
    func method() throws -> HttpMethod
    
    func body() throws -> Any
    
    func urlRequest() throws -> URLRequest
    
    func headers() -> [String : String]?
    
    func params() -> [String : Any]?
    
    func timeout() -> TimeInterval
}

public extension HMNetworkRequestType {
    func baseUrlRequest() throws -> URLRequest {
        let url = try self.url()
        var request = URLRequest(url: url)
        request.httpMethod = try method().rawValue
        request.allHTTPHeaderFields = headers()
        request.timeoutInterval = timeout()
        return request
    }
}
