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
    public typealias Transform = HMTransformMiddleware<A>
    public typealias SideEffect = HMSideEffectMiddleware<A>
    fileprivate var tfMiddlewares: [Transform]
    fileprivate var seMiddlewares: [SideEffect]
    
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
        S: Sequence, S.Iterator.Element == Transform
    {
        return HMTransformers.applyTransformers(result, middlewares)
    }
    
    /// Sequentially apply a Sequence of side effect middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of side effect middlewares.
    func applySideEffectMiddlewares<S>(_ result: A, _ middlewares: S) where
        S: Sequence, S.Iterator.Element == SideEffect
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

extension HMMiddlewareManager: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var manager: Buildable
        
        fileprivate init() {
            manager = Buildable()
        }
        
        /// Add a transform middleware.
        ///
        /// - Parameter transform: A Transform instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(transform: @escaping Transform) -> Self {
            manager.tfMiddlewares.append(transform)
            return self
        }
        
        /// Add a Transform middleware only in debug mode.
        ///
        /// - Parameter transform: A Transform instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func addDebug(transform: @escaping Transform) -> Self {
            return isInDebugMode() ? self.add(transform: transform) : self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of Transform.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == Transform
        {
            manager.tfMiddlewares.append(contentsOf: transforms)
            return self
        }
        
        /// Add multiple transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: A Sequence of Transform.
        /// - Returns: The current Builder instance.
        public func addDebug<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == Transform
        {
            return isInDebugMode() ? with(transforms: transforms) : self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter transforms: Varargs of Transform.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(transforms: Transform...) -> Self {
            return add(transforms: transforms)
        }
        
        /// Add multiple transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: Varargs of Transform.
        /// - Returns: The current Builder instance.
        public func addDebug(transforms: Transform...) -> Self {
            return addDebug(transforms: transforms)
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == Transform
        {
            manager.tfMiddlewares.removeAll()
            return add(transforms: transforms)
        }
        
        /// Replace all transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: A Sequence of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func withDebug<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == Transform
        {
            return isInDebugMode() ? with(transforms: transforms) : self
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter transforms: Varargs of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func with(transforms: Transform...) -> Self {
            return with(transforms: transforms)
        }
        
        /// Replace all transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: Varargs of HMTransformMiddleware.
        /// - Returns: The current Builder instance.
        public func withDebug(transforms: Transform...) -> Self {
            return withDebug(transforms: transforms)
        }
        
        /// Add a side effect middleware.
        ///
        /// - Parameter sideEffect: A HMSideEffectMiddleware instance.
        /// - Returns: The current Builder instance.
        public func add(sideEffect: @escaping SideEffect) -> Self {
            manager.seMiddlewares.append(sideEffect)
            return self
        }
        
        /// Add a side effect middleware only in debug mode.
        ///
        /// - Parameter sideEffect: A HMSideEffectMiddleware instance.
        /// - Returns: The current Builder instance.
        public func addDebug(sideEffect: @escaping SideEffect) -> Self {
            return isInDebugMode() ? add(sideEffect: sideEffect) : self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == SideEffect
        {
            manager.seMiddlewares.append(contentsOf: sideEffects)
            return self
        }
        
        /// Add multiple side effect middlewares only in debug mode.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func addDebug<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == SideEffect
        {
            return isInDebugMode() ? add(sideEffects: sideEffects) : self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func add(sideEffects: SideEffect...) -> Self {
            return add(sideEffects: sideEffects)
        }
        
        /// Add multiple side effect middlewares only in debug mode.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func addDebug(sideEffects: SideEffect...) -> Self {
            return addDebug(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == SideEffect
        {
            manager.seMiddlewares.removeAll()
            return add(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares only debug mode.
        ///
        /// - Parameter sideEffects: A Sequence of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func withDebug<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == SideEffect
        {
            return isInDebugMode() ? with(sideEffects: sideEffects) : self
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func with(sideEffects: SideEffect...) -> Self {
            return with(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares only in debug mode.
        ///
        /// - Parameter sideEffects: Varargs of HMSideEffectMiddleware.
        /// - Returns: The current Builder instance.
        public func withDebug(sideEffects: SideEffect...) -> Self {
            return withDebug(sideEffects: sideEffects)
        }
        
        /// Add logging middleware.
        ///
        /// - Returns: The current Builder instance.
        public func addLoggingMiddleware() -> Self {
            return add(sideEffect: HMMiddlewares.loggingMiddleware())
        }
        
        /// Add logging middleware only in debug mode.
        ///
        /// - Returns: The current Builder instance.
        public func addLoggingMiddlewareInDebug() -> Self {
            return isInDebugMode() ? addLoggingMiddleware() : self
        }
    }
}

extension HMMiddlewareManager.Builder: HMBuilderType {
    public typealias Buildable = HMMiddlewareManager<A>
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return self
            .add(transforms: buildable.tfMiddlewares)
            .add(sideEffects: buildable.seMiddlewares)
    }
    
    public func build() -> HMMiddlewareManager<A> {
        return manager
    }
}
