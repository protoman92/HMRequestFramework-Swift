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
    fileprivate var urlSession: URLSession?
    
    fileprivate init() {}
    
    /// Perform a network request with required dependencies.
    ///
    /// - Parameter request: A HMNetworkRequestType instance.
    /// - Returns: An Observable instance.
    func execute(request: HMNetworkRequestType) throws -> Observable<Try<Data>> {
        if let urlSession = self.urlSession {
            let urlRequest = try request.urlRequest()
            
            return urlSession
                .rx.data(request: urlRequest)
                .retry(request.retries())
                .map(Try.success)
                .catchErrorJustReturn(Try.failure)
                .ifEmpty(default: Try.failure(Exception("Empty response")))
        } else {
            throw Exception("URLSession cannot be nil")
        }
    }
    
    /// Perform a network request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    public func execute<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequestType>)
        -> Observable<Try<Data>>
    {
        return execute(previous, generator, execute)
    }
}

extension HMNetworkRequestHandler: HMNetworkRequestHandlerType {
    public typealias Req = HMNetworkRequestType
}

public extension HMNetworkRequestHandler {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public class Builder {
        private var handler: HMNetworkRequestHandler
        
        fileprivate init() {
            handler = HMNetworkRequestHandler()
        }
        
        /// Set the URLSession instance.
        ///
        /// - Parameter urlSession: A URLSession instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(urlSession: URLSession) -> Builder {
            handler.urlSession = urlSession
            return self
        }
        
        public func build() -> HMNetworkRequestHandler {
            return handler
        }
    }
}
