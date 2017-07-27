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
    
    func timeout() throws -> TimeInterval
    
    func headers() throws -> [String : String]?
    
    func params() throws -> [String : Any]?
    
    func body() throws -> Any?
    
    func urlRequest() throws -> URLRequest
}

public extension HMNetworkRequestType {
    func baseUrlRequest() throws -> URLRequest {
        let url = try self.url()
        var request = URLRequest(url: url)
        request.httpMethod = try method().rawValue
        request.timeoutInterval = try timeout()
        request.allHTTPHeaderFields = try headers()
        return request
    }
}
