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
    fileprivate var rqMiddlewares: [HMRequestMiddleware<A>]
    
    fileprivate init() {
        rqMiddlewares = []
    }
}

extension HMMiddlewareManager: HMMiddlewareManagerType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A Sequence of HMRequestMiddleware.
    public func middlewares() -> [HMRequestMiddleware<A>] {
        return rqMiddlewares
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
            manager.rqMiddlewares.append(middleware)
            return self
        }
        
        /// Add multiple middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMRequestMiddleware<A>
        {
            manager.rqMiddlewares.append(contentsOf: middlewares)
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
            manager.rqMiddlewares.removeAll()
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
