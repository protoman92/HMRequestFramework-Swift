//
//  HMRequestMiddleware.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// This middleware can transform an emission from upstream into one of the
/// same type, but with possibly different properties.
public typealias HMTransformMiddleware<A> = (Try<A>) throws -> Observable<Try<A>>

/// This middleware can perform side effects on an upstream emission. We should
/// only use it for logging events.
public typealias HMSideEffectMiddleware<A> = (Try<A>) throws -> Void

/// Utility class to provide common middlewares.
public final class HMMiddlewares {
    
    /// This middleware logs emission from upstream.
    ///
    /// - Returns: A HMSideEffectMiddleware instance.
    public static func loggingMiddleware<A>() -> HMSideEffectMiddleware<A> {
        return {
            do {
                try print($0.getOrThrow())
            } catch let e {
                print(e)
            }
        }
    }
}
