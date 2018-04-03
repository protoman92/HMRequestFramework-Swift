//
//  HMRequestGenerator.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftFP

/// The request generator is responsible for mapping the result from an
/// upstream request into a request. The reason why the previous result is
/// wrapped in an Try is because we may want to proceed with the current
/// request even if there are errors upstream (e.g. recoverable errors).
public typealias HMRequestGenerator<Prev,Req> = (Try<Prev>) throws -> Observable<Try<Req>>
