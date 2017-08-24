//
//  HMTransformMiddleware.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// This middleware can transform an emission from upstream into one of the
/// same type, but with possibly different properties.
public typealias HMTransformMiddleware<A> = HMTransformer<A>

/// This middleware can perform side effects on an upstream emission. We should
/// only use it for logging events.
public typealias HMSideEffectMiddleware<A> = (A) throws -> Void

/// Utility class to provide common middlewares.
public final class HMMiddlewares {
    
    /// This middleware logs emission from upstream.
    ///
    /// - Returns: A HMSideEffectMiddleware instance.
    public static func loggingMiddleware<A>() -> HMSideEffectMiddleware<A> {
        return {print($0)}
    }
    
    /// Convert a side effect middleware into a transform middleware. This
    /// can be convenient if we want to have only one Array of transform
    /// middlewares in a middleware manager.
    ///
    /// - Parameter sideEffectMiddleware: A HMSideEffectMiddleware instance.
    /// - Returns: A HMTransformMiddleware instance.
    public static func transformFromSideEffect<A>(
        _ sideEffectMiddleware: @escaping HMSideEffectMiddleware<A>)
        -> HMTransformMiddleware<A> where
        A: HMMiddlewareFilterableType
    {
        return {
            try? sideEffectMiddleware($0)
            return Observable.just($0)
        }
    }
}
