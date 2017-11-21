//
//  HMResultProcessors.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/1/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Common result processors.
public final class HMResultProcessors {
    
    /// Convenience method to process the result from some request into a
    /// specified type.
    ///
    /// - Parameters:
    ///   - previous: A Try instance that contains the request result.
    ///   - processor: A HMResultProcessor instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the processing fails.
    public static func processResultFn<Val,Res>(
        _ previous: Try<Val>,
        _ processor: @escaping HMResultProcessor<Val,Res>) throws
        -> Observable<Try<Res>>
    {
        do {
            return try processor(previous.getOrThrow())
        } catch let e {
            return Observable.just(Try.failure(e))
        }
    }
    
    /// Get a result processor that does no transformation.
    ///
    /// - Returns: A HMResultProcessor instance.
    public static func eqProcessor<Val>() -> HMResultProcessor<Val,Val> {
        return {Observable.just(Try.success($0))}
    }
    
    /// Get a result processor that does no transformation.
    ///
    /// - Parameter cls: The Val class type.
    /// - Returns: A HMResultProcessor instance.
    public static func eqProcessor<Val>(_ cls: Val.Type) -> HMResultProcessor<Val,Val> {
        return eqProcessor()
    }
    
    private init() {}
}
