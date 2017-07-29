//
//  HMNetworkRequestHandlerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/22/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle network requests.
public protocol HMNetworkRequestHandlerType: HMRequestHandlerType {
    
    /// Perform a network request.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    /// - Returns: An Observable instance.
    func execute<Prev>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,HMNetworkRequest>)
        -> Observable<Try<Data>>
}
