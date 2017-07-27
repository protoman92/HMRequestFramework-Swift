//
//  HMRequestGenerator.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// The request generator is responsible for mapping the result from an
/// upstream request into a request. The reason why the previous result is 
/// wrapped in an Try is because we may want to proceed with the current 
/// request even if there are errors upstream (e.g. recoverable errors).
public typealias HMRequestGenerator<Prev,Req> = (Try<Prev>) throws -> Observable<Try<Req>>

/// Common request generators.
public final class HMRequestGenerators {
    
    /// This convenience method helps create a default HMRequestGenerator
    /// that forcefully extract the value of the previous Try and throw/catch 
    /// the resulting Exception if it is not available.
    public static func forceGenerateFn<Prev,Req>(
        generator: @escaping (Prev) throws -> Observable<Req>)
        -> HMRequestGenerator<Prev,Req>
    {
        return {$0.rx.get().flatMap(generator)
            .map(Try<Req>.success)
            .catchErrorJustReturn(Try<Req>.failure)}
    }
    
    private init() {}
}
