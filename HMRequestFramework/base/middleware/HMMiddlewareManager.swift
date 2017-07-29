//
//  HMMiddlewareManager.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Utility class to handle request middlewares. This does not handle errors
/// by default.
///
/// If a request handler uses this class, it must catch errors and wrap in
/// Try itself.
public struct HMMiddlewareManager<A> {
    fileprivate var tfMiddlewares: [HMTransformMiddleware<A>]
    fileprivate var seMiddlewares: [HMSideEffectMiddleware<A>]
    
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
    func applyTransformMiddlewares<S>(_ result: A, _ middlewares: S)
        -> Observable<A> where
        S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
    {
        var chain = Observable.just(result)
                
        for middleware in middlewares {
            chain = chain.flatMap({try middleware($0)})
        }
        
        return chain
    }
    
    /// Sequentially apply a Sequence of side effect middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of side effect middlewares.
    func applySideEffectMiddlewares<S>(_ result: A, _ middlewares: S) where
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
    public func applyTransformMiddlewares(_ result: A) -> Observable<A> {
        return applyTransformMiddlewares(result, tfMiddlewares).ifEmpty(default: result)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter result: The original object to be applied on.
    public func applySideEffectMiddlewares(_ result: A) {
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
        /// - Parameter transform: A HMTransformMiddleware instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(transform: @escaping HMTransformMiddleware<A>) -> Builder<A> {
            manager.tfMiddlewares.append(transform)
            return self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(transforms: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
        {
            manager.tfMiddlewares.append(contentsOf: transforms)
            return self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter transforms: Varargs of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func add(transforms: HMTransformMiddleware<A>...) -> Builder<A> {
            return add(transforms: transforms)
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(transforms: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMTransformMiddleware<A>
        {
            manager.tfMiddlewares.removeAll()
            return add(transforms: transforms)
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter transforms: Varargs of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func with(transforms: HMTransformMiddleware<A>...) -> Builder<A> {
            return with(transforms: transforms)
        }
        
        /// Add a side effect middleware.
        ///
        /// - Parameter sideEffect: A HMSideEffectMiddleware instance.
        /// - Returns: The current Builder instance.
        public func add(sideEffect: @escaping HMSideEffectMiddleware<A>) -> Builder<A> {
            manager.seMiddlewares.append(sideEffect)
            return self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(sideEffects: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMSideEffectMiddleware<A>
        {
            manager.seMiddlewares.append(contentsOf: sideEffects)
            return self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add(sideEffects: HMSideEffectMiddleware<A>...) -> Builder<A> {
            return add(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(sideEffects: S) -> Builder<A> where
            S: Sequence, S.Iterator.Element == HMSideEffectMiddleware<A>
        {
            manager.seMiddlewares.removeAll()
            return add(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with(sideEffects: HMSideEffectMiddleware<A>...) -> Builder<A> {
            return with(sideEffects: sideEffects)
        }
        
        /// Add logging middleware.
        ///
        /// - Returns: The current Builder instance.
        public func addLoggingMiddleware() -> Builder<A> {
            return add(sideEffect: HMMiddlewares.loggingMiddleware())
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
