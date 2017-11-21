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
    
    /// One way for uploading - with a data object.
    ///
    /// - Returns: A Data instance.
    func uploadData() -> Data?
    
    /// One way for uploading - with a URL object that points to some resource
    /// in the file system.
    ///
    /// - Returns: A URL instance.
    func uploadURL() -> URL?
    
    func headers() -> [String : String]?
    
    func params() -> [URLQueryItem]
    
    func timeout() -> TimeInterval
}

public extension HMNetworkRequestType {
    
    /// Get the base URLRequest that does not contain a body.
    ///
    /// - Returns: A URLRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    func baseUrlRequest() throws -> URLRequest {
        var urlString = try self.urlString()
        let params = self.params()
        
        if params.isNotEmpty {
            var components = URLComponents(string: "\(urlString)?")
            components?.queryItems = params
            
            if let urlWithParams = components?.url?.absoluteString {
                urlString = urlWithParams
            }
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
    /// to the URLRequest. This URLRequest may contain the body as well.
    ///
    /// - Returns: A URLRequest instance.
    /// - Throws: Exception if the request cannot be generated.
    public func urlRequest() throws -> URLRequest {
        let method = try self.operation()
        var request = try baseUrlRequest()
        
        switch method {
        case .post, .put, .patch:
            let body = try self.body()
            let options: JSONSerialization.WritingOptions = .prettyPrinted
            let httpBody = try JSONSerialization.data(withJSONObject: body, options: options)
            request.httpBody = httpBody
            
        default:
            break
        }
        
        return request
    }
}
