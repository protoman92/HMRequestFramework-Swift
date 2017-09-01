//
//  HMRequestPerformer.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/1/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// This performer is responsible for executing a request and produce some result.
public typealias HMRequestPerformer<Req,Val> = (Req) throws -> Observable<Try<Val>>
