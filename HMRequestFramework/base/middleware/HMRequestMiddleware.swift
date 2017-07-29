//
//  HMRequestMiddleware.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Request handlers should register these middlewares to intercept the request
/// processing.
public typealias HMRequestMiddleware<A> = (Try<A>) throws -> Observable<Try<A>>
