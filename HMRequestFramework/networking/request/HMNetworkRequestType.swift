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
/// using the associated HttpOperation.
public protocol HMNetworkRequestType: HMRequestType, HMNetworkResourceType {
    func operation() throws -> HttpOperation
    
    func body() throws -> Any
    
    func inputStream() throws -> InputStream
    
    func headers() -> [String : String]?
    
    func params() -> [URLQueryItem]
    
    func timeout() -> TimeInterval
}

public extension HMNetworkRequestType {
    func baseUrlRequest() throws -> URLRequest {
        var urlString = try self.urlString()
        var components = URLComponents(string: "\(urlString)?")
        components?.queryItems = params()
        
        if let urlWithParams = components?.url?.absoluteString {
            urlString = urlWithParams
        }
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = try operation().method()
            request.allHTTPHeaderFields = headers()
            request.timeoutInterval = timeout()
            return request
        } else {
            throw Exception("Request cannot be constructed")
        }
    }
    
    /// Depending on the operation, we will need to add additional parameters
    /// to the URLRequest.
    ///
    /// - Returns: A URLRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func urlRequest() throws -> URLRequest {
        let method = try self.operation()
        var request = try baseUrlRequest()
        
        switch method {
        case .post, .put:
            request.httpBody = try JSONSerialization.data(
                withJSONObject: try self.body(),
                options: .prettyPrinted)
            
        case .upload:
            request.httpBodyStream = try inputStream()
            
        default:
            break
        }
        
        return request
    }
}
