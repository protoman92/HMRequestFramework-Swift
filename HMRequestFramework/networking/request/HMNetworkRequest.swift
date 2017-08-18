//
//  HMNetworkRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Foundation
import SwiftUtilities

/// Use this concrete class whenever a HMNetworkRequestType is needed.
public struct HMNetworkRequest {
    fileprivate var httpURL: String?
    fileprivate var httpMethod: HttpOperation?
    fileprivate var httpParams: [URLQueryItem]
    fileprivate var httpHeaders: [String : String]
    fileprivate var httpBody: Any?
    fileprivate var httpInputStream: InputStream?
    fileprivate var timeoutInterval: TimeInterval
    fileprivate var retryCount: Int
    fileprivate var middlewaresEnabled: Bool
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        retryCount = 1
        httpParams = []
        httpHeaders = [:]
        middlewaresEnabled = false
        timeoutInterval = TimeInterval.infinity
    }
}

extension HMNetworkRequest: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: Buildable
        
        fileprivate init() {
            request = Buildable()
        }
        
        /// Set the url string.
        ///
        /// - Parameter endPoint: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlString: String?) -> Self {
            request.httpURL = urlString
            return self
        }
        
        /// Set the endPoint and baseUrl using a resource type.
        ///
        /// - Parameter resource: A HMNetworkResourceType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(resource: HMNetworkResourceType) -> Self {
            return with(urlString: try? resource.urlString())
        }
        
        /// Set the HTTP method.
        ///
        /// - Parameter operation: A HttpOperation instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(operation: HttpOperation?) -> Self {
            request.httpMethod = operation
            return self
        }
        
        /// Set the timeout.
        ///
        /// - Parameter timeout: A TimeInterval instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(timeout: TimeInterval) -> Self {
            request.timeoutInterval = timeout
            return self
        }
        
        /// Add request params.
        ///
        /// - Parameter params: A Dictionary of params.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(params: [String : Any]?) -> Self {
            return add(params: params?
                .map({($0.key, String(describing: $0.value))})
                .map({URLQueryItem(name: $0.0, value: $0.1)}) ?? [])
        }
        
        /// Set request params.
        ///
        /// - Parameter params: A Dictionary of params.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(params: [String : Any]?) -> Self {
            request.httpParams.removeAll()
            return add(params: params)
        }
        
        /// Set the request params.
        ///
        /// - Parameter params: A Sequence of URLQueryItem.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(params: S) -> Self where
            S: Sequence, S.Iterator.Element == URLQueryItem
        {
            request.httpParams.removeAll()
            return add(params: params)
        }
        
        /// Add request params.
        ///
        /// - Parameter param: A Sequence of URLQueryItem.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add<S>(params: S) -> Self where
            S: Sequence, S.Iterator.Element == URLQueryItem
        {
            request.httpParams.append(contentsOf: params)
            return self
        }
        
        /// Add a request param.
        ///
        /// - Parameter param: A URLQueryItem instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(param: URLQueryItem) -> Self {
            request.httpParams.append(param)
            return self
        }
        
        /// Set the request headers.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(headers: [String : String]?) -> Self {
            request.httpHeaders = headers ?? [:]
            return self
        }
        
        /// Update request headers.
        ///
        /// - Parameter headers: A Dictionary of headers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(headers: [String : String]?) -> Self {
            request.httpHeaders.updateValues(from: headers ?? [:])
            return self
        }
        
        /// Set the body.
        ///
        /// - Parameter body: Any object.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(body: Any?) -> Self {
            request.httpBody = body
            return self
        }
        
        /// Set the request inputStream.
        ///
        /// - Parameter inputStream: An InputStream instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(inputStream: InputStream?) -> Self {
            request.httpInputStream = inputStream
            return self
        }
        
        /// Set the request inputStream.
        ///
        /// - Parameter uploadData: A Data instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(uploadData: Data?) -> Self {
            if let data = uploadData {
                return with(inputStream: InputStream(data: data))
            } else {
                return self
            }
        }
        
        /// Set the request inputStream.
        ///
        /// - Parameter uploadURL: A URL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(uploadURL: URL?) -> Self {
            if let url = uploadURL {
                return with(inputStream: InputStream(url: url))
            } else {
                return self
            }
        }
        
        /// Set the request inputStream
        ///
        /// - Parameter uploadFilePath: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(uploadFilePath: String?) -> Self {
            if let path = uploadFilePath {
                return with(inputStream: InputStream(fileAtPath: path))
            } else {
                return self
            }
        }
    }
}

extension HMNetworkRequest: HMProtocolConvertibleType {
    public typealias PTCType = HMNetworkRequestType
    
    public func asProtocol() -> PTCType {
        return self as PTCType
    }
}

extension HMNetworkRequest.Builder: HMProtocolConvertibleBuilderType {
    public typealias Buildable = HMNetworkRequest
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter generic: A HMNetworkRequestType.
    /// - Returns: The current Builder instance.
    public func with(generic: Buildable.PTCType) -> Self {
        return self
            .with(urlString: try? generic.urlString())
            .with(operation: try? generic.operation())
            .with(body: try? generic.body())
            .with(headers: generic.headers())
            .with(params: generic.params())
            .with(inputStream: try? generic.inputStream())
            .with(timeout: generic.timeout())
            .with(retries: generic.retries())
            .with(applyMiddlewares: generic.applyMiddlewares())
            .with(requestDescription: generic.requestDescription())
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return with(generic: buildable)
    }
}

extension HMNetworkRequest.Builder: HMRequestBuilderType {

    /// Override this method to provide default implementation.
    ///
    /// - Parameter retries: An Int value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(retries: Int) -> Self {
        request.retryCount = retries
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter applyMiddlewares: A Bool value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(applyMiddlewares: Bool) -> Self {
        request.middlewaresEnabled = applyMiddlewares
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter requestDescription: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(requestDescription: String?) -> Self {
        request.rqDescription = requestDescription
        return self
    }
    
    public func build() -> Buildable {
        return request
    }
}

extension HMNetworkRequest: HMNetworkRequestType {
    public func urlString() throws -> String {
        if let url = self.httpURL {
            return url
        } else {
            throw Exception("URL cannot be nil")
        }
    }
    
    public func operation() throws -> HttpOperation {
        if let method = httpMethod {
            return method
        } else {
            throw Exception("Operation cannot be nil")
        }
    }
    
    public func body() throws -> Any {
        if let body = httpBody {
            return body
        } else {
            throw Exception("Body cannot be nil")
        }
    }
    
    public func inputStream() throws -> InputStream {
        if let inputStream = httpInputStream {
            return inputStream
        } else {
            throw Exception("Input stream cannot be nil")
        }
    }
    
    public func params() -> [URLQueryItem] {
        return httpParams
    }
    
    public func headers() -> [String : String]? {
        return httpHeaders.isEmpty ? nil : httpHeaders
    }
    
    public func timeout() -> TimeInterval {
        return timeoutInterval
    }
    
    public func retries() -> Int {
        return Swift.max(retryCount, 1)
    }
    
    public func applyMiddlewares() -> Bool {
        return middlewaresEnabled
    }
    
    public func requestDescription() -> String? {
        return rqDescription
    }
}

extension HMNetworkRequest: CustomStringConvertible {
    public var description: String {
        let method = (try? self.operation().method()) ?? "INVALID METHOD"
        let url = (try? self.url().absoluteString) ?? "INVALID URL"
        let description = (self.requestDescription()) ?? "NONE"
        return "Performing \(method) at: \(url). Description: \(description)"
    }
}
