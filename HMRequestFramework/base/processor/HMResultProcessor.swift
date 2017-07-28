//
//  HMResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Instead of declaring concrete types when perform requests, we delegate the 
/// processing to an external function. This would decouple responsibilities.
public typealias HMResultProcessor<Val,Res> = (Val) throws -> Observable<Try<Res>>

public typealias HMProtocolResultProcessor<Val: HMProtocolConvertibleType> =
    HMResultProcessor<Val,Val.PTCType>

/// Common result processors.

public final class HMResultProcessors {
    
    /// Convenience method to process the result from some request into a
    /// specified type.
    ///
    /// - Parameters:
    ///   - previous: A Try instance that contains the request result.
    ///   - processor: Processor function to convert said result into some type.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the processing fails.
    public static func processResultFn<Val,Res>(
        _ previous: Try<Val>,
        _ processor: @escaping HMResultProcessor<Val,Res>) throws
        -> Observable<Try<Res>>
    {
        return previous.rx.get()
            .flatMap(processor)
            .catchErrorJustReturn(Try.failure)
    }
    
    private init() {}
}
