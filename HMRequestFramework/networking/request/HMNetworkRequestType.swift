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
    
    /// Be mindful that these is only basic params support. For anything more
    /// complicated (like nested Arrays/Dicts), please flatten first.
    ///
    /// - Returns: A Dictionary instance.
    func params() -> [String : Any]?
    
    func timeout() -> TimeInterval
}

public extension HMNetworkRequestType {
    func baseUrlRequest() throws -> URLRequest {
        var urlString = try self.urlString()
        
        // If there are request params, append them to the end of the URL.
        if let params = self.params() {
            var components = URLComponents(string: "\(urlString)?")
            
            components?.queryItems = params
                .map({($0.key, String(describing: $0.value))})
                .map({URLQueryItem(name: $0.0, value: $0.1)})
            
            if let urlWithParams = components?.url?.absoluteString {
                urlString = urlWithParams
            }
        }
        
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = try method().rawValue
            request.allHTTPHeaderFields = headers()
            request.timeoutInterval = timeout()
            return request
        } else {
            throw Exception("Request cannot be constructed")
        }
    }
}
