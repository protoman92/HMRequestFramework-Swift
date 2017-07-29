//
//  HMRequestMiddlewares.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Utility class to handle request middlewares.
public struct HMMiddlewareManager<A> {
    fileprivate var middlewares: [HMRequestMiddleware<A>]
    
    fileprivate init() {
        middlewares = []
    }
    
    /// Sequentially apply a Sequence of middlewares.
    ///
    /// - Parameters:
    ///   - original: The original object to be applied on.
    ///   - middlewares: A Sequence of middlewares.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the application fails.
    func applyMiddlewares<S>(_ original: Try<A>, _ middlewares: S) throws
        -> Observable<Try<A>> where
        S: Sequence, S.Iterator.Element == HMRequestMiddleware<A>
    {
        let middlewares = middlewares.map(eq)
        
        if let first = middlewares.first {
            var chain = try first(original)
            
            for (index, middleware) in middlewares.enumerated() {
                if (index > 0) {
                    chain = chain.flatMap(middleware)
                }
            }
            
            return chain
        } else {
            return Observable.empty()
        }
    }
    
    /// Apply registered middlewares.
    ///
    /// - Parameter original: The original object to be applied on.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the application fails.
    func applyMiddlewares(_ original: Try<A>) throws -> Observable<Try<A>> {
        let middlewares = self.middlewares
        return try applyMiddlewares(original, middlewares)
    }
}

public extension HMMiddlewareManager {
    public final class Builder<A> {
        private var manager: HMMiddlewareManager<A>
        
        fileprivate init() {
            manager = HMMiddlewareManager<A>()
        }
        
        /// Add a middleware.
        ///
        /// - Parameter middleware: A HMRequestMiddleware instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(middleware: @escaping HMRequestMiddleware<A>) -> Builder<A> {
            manager.middlewares.append(middleware)
            return self
        }
        
        /// Add multiple middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMRequestMiddleware<A>
        {
            manager.middlewares.append(contentsOf: middlewares)
            return self
        }
        
        /// Add multiple middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func add(middlewares: HMRequestMiddleware<A>...) -> Builder<A> {
            return add(middlewares: middlewares)
        }
        
        /// Replace all middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMRequestMiddleware<A>
        {
            manager.middlewares.removeAll()
            return add(middlewares: middlewares)
        }
        
        /// Replace all middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func with(middlewares: HMRequestMiddleware<A>...) -> Builder<A> {
            return with(middlewares: middlewares)
        }
        
        public func build() -> HMMiddlewareManager<A> {
            return manager
        }
    }
}
