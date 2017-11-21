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
    fileprivate var httpUploadedData: Data?
    fileprivate var httpUploadURL: URL?
    fileprivate var nwMWFilters: [MiddlewareFilter]
    fileprivate var timeoutInterval: TimeInterval
    fileprivate var retryCount: Int
    fileprivate var retryDelayIntv: TimeInterval
    fileprivate var middlewaresEnabled: Bool
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        retryCount = 1
        retryDelayIntv = 0
        httpParams = []
        httpHeaders = [:]
        nwMWFilters = []
        middlewaresEnabled = true
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
        
        /// Transform the url string if it is available.
        ///
        /// - Parameter urlTransform: Transform function.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlTransform: (String) throws -> String?) -> Self {
            if let url1 = try? request.urlString(), let url2 = try? urlTransform(url1) {
                return with(urlString: url2)
            } else {
                return self
            }
        }
        
        /// Add base url to the request's existing url string if available.
        ///
        /// - Parameter baseUrl: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(baseUrl: String?) -> Self {
            if let baseUrl = baseUrl {
                return with(urlTransform: {"\(baseUrl)/\($0)"})
            } else {
                return self
            }
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
            S: Sequence, S.Element == URLQueryItem
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
            S: Sequence, S.Element == URLQueryItem
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
        
        /// Update request headers.
        ///
        /// - Parameters:
        ///   - header: A String value.
        ///   - key: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(header: String?, forKey key: String) -> Self {
            if let header = header {
                request.httpHeaders.updateValue(header, forKey: key)
            }
            
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
        /// - Parameter uploadData: A Data instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(uploadData: Data?) -> Self {
            request.httpUploadedData = uploadData
            return self
        }
        
        /// Set the request inputStream.
        ///
        /// - Parameter uploadURL: A URL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(uploadURL: URL?) -> Self {
            request.httpUploadURL = uploadURL
            return self
        }
    }
}

extension HMNetworkRequest.Builder: HMRequestBuilderType {
    public typealias Buildable = HMNetworkRequest

    /// Override this method to provide default implementation.
    ///
    /// - Parameter mwFilters: An Array of filters.
    /// - Returns: The current Builder instance.
    public func with<S>(mwFilters: S) -> Self where
        S: Sequence, S.Element == HMMiddlewareFilter<Buildable>
    {
        request.nwMWFilters = mwFilters.map({$0})
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter mwFilter: A filter instance.
    /// - Returns: The current Builder instance.
    public func add(mwFilter: HMMiddlewareFilter<Buildable>) -> Self {
        request.nwMWFilters.append(mwFilter)
        return self
    }
    
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
    /// - Parameter retries: An Int value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(retryDelay: TimeInterval) -> Self {
        request.retryDelayIntv = retryDelay
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
    /// - Parameter description: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(description: String?) -> Self {
        request.rqDescription = description
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(urlString: buildable.httpURL)
                .with(operation: buildable.httpMethod)
                .with(body: buildable.httpBody)
                .with(headers: buildable.httpHeaders)
                .with(params: buildable.httpParams)
                .with(uploadData: buildable.httpUploadedData)
                .with(uploadURL: buildable.httpUploadURL)
                .with(timeout: buildable.timeoutInterval)
                .with(mwFilters: buildable.nwMWFilters)
                .with(retries: buildable.retryCount)
                .with(retryDelay: buildable.retryDelayIntv)
                .with(applyMiddlewares: buildable.middlewaresEnabled)
                .with(description: buildable.rqDescription)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return request
    }
}

extension HMNetworkRequest: HMRequestType {
    public typealias Filterable = String
    
    public func middlewareFilters() -> [MiddlewareFilter] {
        return nwMWFilters
    }
    
    public func retries() -> Int {
        return Swift.max(retryCount, 1)
    }
    
    public func retryDelay() -> TimeInterval {
        return retryDelayIntv
    }
    
    public func applyMiddlewares() -> Bool {
        return middlewaresEnabled
    }
    
    public func requestDescription() -> String? {
        return rqDescription
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
    
    public func uploadData() -> Data? {
        return httpUploadedData
    }
    
    public func uploadURL() -> URL? {
        return httpUploadURL
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
}

extension HMNetworkRequest: CustomStringConvertible {
    public var description: String {
        let method = (try? self.operation().method()) ?? "INVALID METHOD"
        let url = (try? self.url().absoluteString) ?? "INVALID URL"
        let description = (self.requestDescription()) ?? "NONE"
        return "Performing \(method) at: \(url). Description: \(description)"
    }
}

