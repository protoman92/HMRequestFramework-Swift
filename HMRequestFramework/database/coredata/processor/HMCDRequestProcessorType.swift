//
//  HMCDRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/22/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to perform CoreData
/// requests and process the result.
public protocol HMCDRequestProcessorType: HMRequestHandlerType, HMCDObjectConstructorType {
    
    /// Perform a CoreData get request with required dependencies. This method
    /// should be used for CoreData operations whose results are constrained
    /// to some NSManagedObject subtype.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    func executeTyped<Val>(_ request: Req) throws -> Observable<Try<Val>>
        where Val: NSFetchRequestResult
    
    /// Perform a CoreData request with required dependencies.
    ///
    /// This method should be used with operations that do not require specific
    /// result type, e.g. CoreData save requests.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    func execute(_ request: Req) throws -> Observable<Try<Void>>
}

public extension HMCDRequestProcessorType {

    /// Perform a CoreData get request and process the result.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the request result.
    /// - Returns: An Observable instance.
    public func process<Prev,Val,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<Val,Res>)
        -> Observable<Try<Res>>
        where Val: NSFetchRequestResult
    {
        return execute(previous, generator, executeTyped)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
    
    /// Override this method to provide default implementation.
    ///
    /// This method should be used for all operations other than those which
    /// require specific NSManagedObject subtypes.
    ///
    /// - Parameters:
    ///   - previous: The result of the upstream request.
    ///   - generator: Generator function to create the current request.
    ///   - processor: Processor function to process the request result.
    /// - Returns: An Observable instance.
    public func process<Prev,Res>(
        _ previous: Try<Prev>,
        _ generator: @escaping HMRequestGenerator<Prev,Req>,
        _ processor: @escaping HMResultProcessor<Void,Res>)
        -> Observable<Try<Res>>
    {
        return execute(previous, generator, execute)
            .flatMap({try HMResultProcessors.processResultFn($0, processor)})
    }
}
