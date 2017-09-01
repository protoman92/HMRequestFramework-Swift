//
//  HMMiddlewares.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

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
        -> HMTransformMiddleware<A>
    {
        return {
            try? sideEffectMiddleware($0)
            return Observable.just($0)
        }
    }
}
