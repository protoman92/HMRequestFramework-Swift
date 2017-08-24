//
//  HMNetworkRequestHandler.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxCocoa
import RxSwift
import SwiftUtilities

/// Use this class to perform network requests.
public struct HMNetworkRequestHandler {
    fileprivate var nwUrlSession: URLSession?
    fileprivate var rqmManager: HMMiddlewareManager<Req>?
    
    fileprivate init() {}
    
    fileprivate func urlSession() -> URLSession {
        if let urlSession = self.nwUrlSession {
            return urlSession
        } else {
            fatalError("URLSession cannot be nil")
        }
    }
    
    /// Perform a network request with required dependencies.
    ///
    /// - Parameter request: A HMNetworkRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    fileprivate func execute(_ request: Req) throws -> Observable<Try<Data>> {
        let urlSession = self.urlSession()
        let urlRequest = try request.urlRequest()
            
        return urlSession
            .rx.data(request: urlRequest)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Execute a data request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    fileprivate func executeData(_ request: Req) throws -> Observable<Try<Data>> {
        let urlSession = self.urlSession()
        let urlRequest = try request.urlRequest()
        
        return urlSession
            .rx.data(request: urlRequest)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Execute an upload request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    fileprivate func executeUpload(_ request: Req) throws -> Observable<Try<Data>> {
        let urlSession = self.urlSession()
        let urlRequest = try request.urlRequest()
        var uploadTask: Observable<Data>
        
        if let data = request.uploadData() {
            uploadTask = urlSession.rx.uploadWithCompletion(urlRequest, data)
        } else if let url = request.uploadURL() {
            uploadTask = urlSession.rx.uploadWithCompletion(urlRequest, url)
        } else {
            throw Exception("No Data available for upload")
        }
        
        return uploadTask
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Perform a network request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    public func execute<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequest>)
        -> Observable<Try<Data>>
    {
        return execute(previous, generator, execute)
    }
}

extension HMNetworkRequestHandler: HMNetworkRequestHandlerType {
    public typealias Req = HMNetworkRequest
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMMiddlewareManager instance.
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req>? {
        return rqmManager
    }
}

extension HMNetworkRequestHandler: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public class Builder {
        public typealias Req = HMNetworkRequestHandler.Req
        fileprivate var handler: Buildable
        
        fileprivate init() {
            handler = HMNetworkRequestHandler()
        }
        
        /// Set the URLSession instance.
        ///
        /// - Parameter urlSession: A URLSession instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlSession: URLSession) -> Self {
            handler.nwUrlSession = urlSession
            return self
        }
        
        /// Set the request middleware manager instance.
        ///
        /// - Parameter rqmManager: A HMMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(rqmManager: HMMiddlewareManager<Req>?) -> Self {
            handler.rqmManager = rqmManager
            return self
        }
    }
}

extension HMNetworkRequestHandler.Builder: HMBuilderType {
    public typealias Buildable = HMNetworkRequestHandler
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A HMNetworkRequestHandler instance
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return self
            .with(urlSession: buildable.urlSession())
            .with(rqmManager: buildable.requestMiddlewareManager())
    }
    
    public func build() -> Buildable {
        return handler
    }
}
