//
//  HMMiddleware.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// This middleware can transform an emission from upstream into one of the
/// same type, but with possibly different properties.
public typealias HMTransformMiddleware<A> = HMTransform<A>

/// This middleware can perform side effects on an upstream emission. We should
/// only use it for logging events.
public typealias HMSideEffectMiddleware<A> = (A) throws -> Void
