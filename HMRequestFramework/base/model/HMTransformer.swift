//
//  HMTransform.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

/// Transform some value into another value of the same type, wrapped in an
/// Observable.
///
/// This is especially useful for change some request parameters for a request
/// object to fit different scenarios. For e.g., two request methods may
/// perform the same functionality, but one may need more retries than the
/// other, or a different description.
public typealias HMTransform<A> = (A) throws -> Observable<A>
