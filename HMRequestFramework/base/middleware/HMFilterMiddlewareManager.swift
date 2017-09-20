//
//  HMFilterMiddlewareManager.swift
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
/// This middleware manager allows middlewares to be filtered, which makes it
/// suitable for handling requests.
///
/// If a request handler uses this class, it must catch errors and wrap in
/// Try itself.
public struct HMFilterMiddlewareManager<Target: HMMiddlewareFilterableType> {
    public typealias Filterable = Target.Filterable
    public typealias Transform = HMTransformMiddleware<Target>
    public typealias SideEffect = HMSideEffectMiddleware<Target>
    var tfMiddlewares: [(Filterable, Transform)]
    var seMiddlewares: [(Filterable, SideEffect)]
    
    fileprivate init() {
        tfMiddlewares = []
        seMiddlewares = []
    }
}

extension HMFilterMiddlewareManager: HMMiddlewareManagerType {
    
    /// Filter out some middlewares.
    ///
    /// - Parameter filterables: An Sequence of Filterable/MW.
    /// - Returns: An Array of Filterable.
    func filterMiddlewares<MW,S>(_ result: Target, _ filterables: S)
        -> [(Filterable, MW)] where
        S: Sequence, S.Iterator.Element == (Filterable, MW)
    {
        let filters = result.middlewareFilters()
        
        return filterables.filter({(filterable, _) in
            filters.all({(try? $0.filter(result, filterable)) ?? false})
        })
    }
    
    /// Sequentially apply a Sequence of transform middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of Filterable/Transform.
    /// - Returns: An Observable instance.
    public func applyTransformMiddlewares<S>(_ result: Target, _ middlewares: S)
        -> Observable<Target> where
        S: Sequence, S.Iterator.Element == (Filterable, Transform)
    {
        let filtered = filterMiddlewares(result, middlewares).map({$0.1})
        return HMTransforms.applyTransformers(result, filtered)
    }
    
    /// Sequentially apply a Sequence of side effect middlewares.
    ///
    /// - Parameters:
    ///   - original: The result object to be applied on.
    ///   - middlewares: A Sequence of Filterable/SideEffect.
    public func applySideEffectMiddlewares<S>(_ result: Target, _ middlewares: S) where
        S: Sequence, S.Iterator.Element == (Filterable, SideEffect)
    {
        let filtered = filterMiddlewares(result, middlewares).map({$0.1})
        filtered.forEach({try? $0(result)})
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter result: The original object to be applied on.
    /// - Returns: An Observable instance.
    public func applyTransformMiddlewares(_ result: Target) -> Observable<Target> {
        return applyTransformMiddlewares(result, tfMiddlewares).ifEmpty(default: result)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter result: The original object to be applied on.
    public func applySideEffectMiddlewares(_ result: Target) {
        return applySideEffectMiddlewares(result, seMiddlewares)
    }
}

extension HMFilterMiddlewareManager: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        var manager: Buildable
        
        fileprivate init() {
            manager = Buildable()
        }
        
        /// Add a transform middleware.
        ///
        /// - Parameters:
        ///   - transform: A Transform instance.
        ///   - key: A Filterable instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(transform: @escaping Transform, forKey key: Filterable) -> Self {
            manager.tfMiddlewares.append((key, transform))
            return self
        }
        
        /// Add a Transform middleware only in debug mode.
        ///
        /// - Parameters:
        ///   - transform: A Transform instance.
        ///   - key: A Filterable instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func addDebug(transform: @escaping Transform,
                             forKey key: Filterable) -> Self {
            return isInDebugMode() ? self.add(transform: transform, forKey: key) : self
        }
        
        /// Add multiple transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of Filterable/Transform.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, Transform)
        {
            manager.tfMiddlewares.append(contentsOf: transforms)
            return self
        }
        
        /// Add multiple transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: A Sequence of Filterable/Transform.
        /// - Returns: The current Builder instance.
        public func addDebug<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, Transform)
        {
            return isInDebugMode() ? with(transforms: transforms) : self
        }
        
        /// Replace all transform middlewares.
        ///
        /// - Parameter transforms: A Sequence of Filterable/Transform.
        /// - Returns: The current Builder instance.
        public func with<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, Transform)
        {
            manager.tfMiddlewares.removeAll()
            return add(transforms: transforms)
        }
        
        /// Replace all transform middlewares only in debug mode.
        ///
        /// - Parameter transforms: A Sequence of Filterable/Transform.
        /// - Returns: The current Builder instance.
        public func withDebug<S>(transforms: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, Transform)
        {
            return isInDebugMode() ? with(transforms: transforms) : self
        }
        
        /// Add a side effect middleware.
        ///
        /// - Parameters:
        ///   - sideEffect: A SideEffect instance.
        ///   - key: A Filterable instance.
        /// - Returns: The current Builder instance.
        public func add(sideEffect: @escaping SideEffect,
                        forKey key: Filterable) -> Self {
            manager.seMiddlewares.append((key, sideEffect))
            return self
        }
        
        /// Add a side effect middleware only in debug mode.
        ///
        /// - Parameters:
        ///   - sideEffect: A SideEffect instance.
        ///   - key: A Filterable instance.
        /// - Returns: The current Builder instance.
        public func addDebug(sideEffect: @escaping SideEffect,
                             forKey key: Filterable) -> Self {
            return isInDebugMode() ? add(sideEffect: sideEffect, forKey: key) : self
        }
        
        /// Add multiple side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of Filterable/SideEffect.
        /// - Returns: The current Builder instance.
        public func add<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, SideEffect)
        {
            manager.seMiddlewares.append(contentsOf: sideEffects)
            return self
        }
        
        /// Add multiple side effect middlewares only in debug mode.
        ///
        /// - Parameter sideEffects: A Sequence of Filterable/SideEffect.
        /// - Returns: The current Builder instance.
        public func addDebug<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, SideEffect)
        {
            return isInDebugMode() ? add(sideEffects: sideEffects) : self
        }
        
        /// Replace all side effect middlewares.
        ///
        /// - Parameter sideEffects: A Sequence of Filterable/SideEffect.
        /// - Returns: The current Builder instance.
        public func with<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, SideEffect)
        {
            manager.seMiddlewares.removeAll()
            return add(sideEffects: sideEffects)
        }
        
        /// Replace all side effect middlewares only debug mode.
        ///
        /// - Parameter sideEffects: A Sequence of Filterable/SideEffect.
        /// - Returns: The current Builder instance.
        public func withDebug<S>(sideEffects: S) -> Self where
            S: Sequence, S.Iterator.Element == (Filterable, SideEffect)
        {
            return isInDebugMode() ? with(sideEffects: sideEffects) : self
        }
    }
}

// MARK: - Global middlewares.
// These are only available if the target conforms to global applicable.

public typealias HMGlobalMiddlewareManager<Target: HMMiddlewareGlobalApplicableType> =
    HMFilterMiddlewareManager<Target>

public extension HMFilterMiddlewareManager.Builder where Target: HMMiddlewareGlobalApplicableType {
    public typealias GBTransform = Buildable.Transform
    public typealias GBSideEffect = Buildable.SideEffect
    
    fileprivate var globalMiddlewareKey: Target.Filterable {
        return "GlobalMiddleware"
    }
    
    /// Add a transform middleware.
    ///
    /// - Parameters transform: A Transform instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func add(transform: @escaping GBTransform) -> Self {
        return add(transform: transform, forKey: globalMiddlewareKey)
    }
    
    /// Add a Transform middleware only in debug mode.
    ///
    /// - Parameters transform: A Transform instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func addDebug(transform: @escaping GBTransform) -> Self {
        return isInDebugMode() ? self.add(transform: transform) : self
    }
    
    /// Add multiple transform middlewares.
    ///
    /// - Parameter transforms: A Sequence of Transform.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func add<S>(transforms: S) -> Self where
        S: Sequence, S.Iterator.Element == GBTransform
    {
        let key = globalMiddlewareKey
        let transforms = transforms.map({(key, $0)})
        return add(transforms: transforms)
    }
    
    /// Add multiple transform middlewares only in debug mode.
    ///
    /// - Parameter transforms: A Sequence of Transform.
    /// - Returns: The current Builder instance.
    public func addDebug<S>(transforms: S) -> Self where
        S: Sequence, S.Iterator.Element == GBTransform
    {
        return isInDebugMode() ? with(transforms: transforms) : self
    }
    
    /// Replace all transform middlewares.
    ///
    /// - Parameter transforms: A Sequence of Transform.
    /// - Returns: The current Builder instance.
    public func with<S>(transforms: S) -> Self where
        S: Sequence, S.Iterator.Element == GBTransform
    {
        let key = globalMiddlewareKey
        let transforms = transforms.map({(key, $0)})
        return with(transforms: transforms)
    }
    
    /// Replace all transform middlewares only in debug mode.
    ///
    /// - Parameter transforms: A Sequence of Transform.
    /// - Returns: The current Builder instance.
    public func withDebug<S>(transforms: S) -> Self where
        S: Sequence, S.Iterator.Element == GBTransform
    {
        return isInDebugMode() ? with(transforms: transforms) : self
    }
    
    /// Add a side effect middleware.
    ///
    /// - Parameters sideEffect: A SideEffect instance.
    /// - Returns: The current Builder instance.
    public func add(sideEffect: @escaping GBSideEffect) -> Self {
        return add(sideEffect: sideEffect, forKey: globalMiddlewareKey)
    }
    
    /// Add a side effect middleware only in debug mode.
    ///
    /// - Parameters sideEffect: A SideEffect instance.
    /// - Returns: The current Builder instance.
    public func addDebug(sideEffect: @escaping GBSideEffect) -> Self {
        return isInDebugMode() ? add(sideEffect: sideEffect) : self
    }
    
    /// Add multiple side effect middlewares.
    ///
    /// - Parameter sideEffects: A Sequence of SideEffect.
    /// - Returns: The current Builder instance.
    public func add<S>(sideEffects: S) -> Self where
        S: Sequence, S.Iterator.Element == GBSideEffect
    {
        let key = globalMiddlewareKey
        let sideEffects = sideEffects.map({(key, $0)})
        return add(sideEffects: sideEffects)
    }
    
    /// Add multiple side effect middlewares only in debug mode.
    ///
    /// - Parameter sideEffects: A Sequence of SideEffect.
    /// - Returns: The current Builder instance.
    public func addDebug<S>(sideEffects: S) -> Self where
        S: Sequence, S.Iterator.Element == GBSideEffect
    {
        return isInDebugMode() ? add(sideEffects: sideEffects) : self
    }
    
    /// Replace all side effect middlewares.
    ///
    /// - Parameter sideEffects: A Sequence of SideEffect.
    /// - Returns: The current Builder instance.
    public func with<S>(sideEffects: S) -> Self where
        S: Sequence, S.Iterator.Element == GBSideEffect
    {
        return with(sideEffects: sideEffects)
    }
    
    /// Replace all side effect middlewares only debug mode.
    ///
    /// - Parameter sideEffects: A Sequence of SideEffect.
    /// - Returns: The current Builder instance.
    public func withDebug<S>(sideEffects: S) -> Self where
        S: Sequence, S.Iterator.Element == GBSideEffect
    {
        return isInDebugMode() ? with(sideEffects: sideEffects) : self
    }
}

extension HMFilterMiddlewareManager.Builder: HMBuilderType {
    public typealias Buildable = HMFilterMiddlewareManager<Target>
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .add(transforms: buildable.tfMiddlewares)
                .add(sideEffects: buildable.seMiddlewares)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return manager
    }
}
