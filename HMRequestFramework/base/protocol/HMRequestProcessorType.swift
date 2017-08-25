//
//  HMRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must base able to perform some request 
/// and process the result.
public protocol HMRequestProcessorType: HMRequestHandlerType {

    /// Perform a request and process the result.
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    /// - Returns: An Observable instance.
    func process<Prev,Val,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<Val,Res>)
        -> Observable<Try<Res>>
}
