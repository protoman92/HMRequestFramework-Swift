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
    
    /// These middlewares have internal access for tests. They will not be
    /// visible for API users.
    var tfMiddlewares: [HMTransformMiddleware<A>]
    var seMiddlewares: [HMSideEffectMiddleware<A>]
    
    fileprivate init() {
        tfMiddlewares = []
        seMiddlewares = []
    }
    
    /// Sequentially apply a Sequence of transform middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of transform middlewares.
    /// - Returns: An Observable instance.
    func applyTransformMiddlewares<S>(_ result: Try<A>, _ middlewares: S)
        -> Observable<Try<A>> where
        S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
    {
        var chain = Observable.just(result)
                
        for middleware in middlewares {
            chain = chain
                .flatMap({try middleware($0).catchErrorJustReturn(Try.failure)})
                .catchErrorJustReturn(Try.failure)
        }
        
        return chain
    }
    
    /// Sequentially apply a Sequence of side effect middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of side effect middlewares.
    func applySideEffectMiddlewares<S>(_ result: Try<A>, _ middlewares: S) where
        S: Sequence, S.Iterator.Element == HMSideEffectMiddleware<A>
    {
        middlewares.forEach({try? $0(result)})
    }
}

extension HMMiddlewareManager: HMMiddlewareManagerType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter result: The original object to be applied on.
    /// - Returns: An Observable instance.
    public func applyTransformMiddlewares(_ result: Try<A>) -> Observable<Try<A>> {
        return applyTransformMiddlewares(result, tfMiddlewares)
            .ifEmpty(default: result)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter result: The original object to be applied on.
    public func applySideEffectMiddlewares(_ result: Try<A>) {
        return applySideEffectMiddlewares(result, seMiddlewares)
    }
}

public extension HMMiddlewareManager {
    public static func builder<A>() -> Builder<A> {
        return Builder()
    }
    
    public final class Builder<A> {
        private var manager: HMMiddlewareManager<A>
        
        fileprivate init() {
            manager = HMMiddlewareManager<A>()
        }
        
        /// Add a transform middleware.
        ///
        /// - Parameter middleware: A HMRequestMiddleware instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(middleware: @escaping HMTransformMiddleware<A>) -> Builder<A> {
            manager.tfMiddlewares.append(middleware)
            return self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
        {
            manager.tfMiddlewares.append(contentsOf: middlewares)
            return self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func add(middlewares: HMTransformMiddleware<A>...) -> Builder<A> {
            return add(middlewares: middlewares)
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
        {
            manager.tfMiddlewares.removeAll()
            return add(middlewares: middlewares)
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMRequestMiddleware.
        /// - Returns: The current Builder instance.
        public func with(middlewares: HMTransformMiddleware<A>...) -> Builder<A> {
            return with(middlewares: middlewares)
        }
        
        /// Add a side effect middleware.
        ///
        /// - Parameter middleware: A HMSideEffectMiddleware instance.
        /// - Returns: The current Builder instance.
        public func add(middleware: @escaping HMSideEffectMiddleware<A>) -> Builder<A> {
            manager.seMiddlewares.append(middleware)
            return self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMSideEffectMiddleware<A>
        {
            manager.seMiddlewares.append(contentsOf: middlewares)
            return self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add(middlewares: HMSideEffectMiddleware<A>...) -> Builder<A> {
            return add(middlewares: middlewares)
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter middlewares: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(middlewares: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMSideEffectMiddleware<A>
        {
            manager.seMiddlewares.removeAll()
            return add(middlewares: middlewares)
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter middlewares: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with(middlewares: HMSideEffectMiddleware<A>...) -> Builder<A> {
            return with(middlewares: middlewares)
        }
        
        /// Add logging middleware.
        ///
        /// - Returns: The current Builder instance.
        public func addLoggingMiddleware() -> Builder<A> {
            return add(middleware: HMMiddlewares.loggingMiddleware())
        }
        
        /// Add logging middleware only in debug mode.
        ///
        /// - Returns: The current Builder instance.
        public func addLoggingMiddlewareInDebug() -> Builder<A> {
            return isInDebugMode() ? addLoggingMiddleware() : self
        }
        
        public func build() -> HMMiddlewareManager<A> {
            return manager
        }
    }
}
