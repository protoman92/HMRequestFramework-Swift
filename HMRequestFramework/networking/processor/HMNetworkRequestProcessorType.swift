//
//  HMNetworkRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to perform network
/// requests and process the results.
public protocol HMNetworkRequestProcessorType {
    
    /// Perform a network request and process the result.
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the result.
    /// - Returns: An Observable instance.
    func process<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequestType>,
        _ processor: @escaping HMResultProcessor<Data,Res>)
        -> Observable<Try<Res>>
}
