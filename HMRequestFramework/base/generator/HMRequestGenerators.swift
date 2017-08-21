//
//  HMRequestGenerators.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 31/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

public typealias HMAnyRequestGenerator<Req> = HMRequestGenerator<Any,Req>
public typealias HMVoidRequestGenerator<Req> = HMRequestGenerator<Void,Req>

/// Common request generators.
public final class HMRequestGenerators {
    
    /// This convenience method helps create a default HMRequestGenerator
    /// that forcefully extract the value of the previous Try and throw/catch
    /// the resulting Exception if it is not available.
    public static func forceGn<Prev,Req>(
        _ generator: @escaping (Prev) throws -> Observable<Req>)
        -> HMRequestGenerator<Prev,Req>
    {
        return {$0.rx.get().flatMap(generator)
            .map(Try<Req>.success)
            .catchErrorJustReturn(Try<Req>.failure)}
    }
    
    /// Create a request generator just from a request object, ignoring the
    /// previous value completely.
    public static func forceGn<Prev,Req>(_ request: Req) -> HMRequestGenerator<Prev,Req> {
        return forceGn({_ in Observable.just(request)})
    }
    
    /// Create a request generator just from a request object, ignoring the
    /// previous value completely. We also specify the type of the previous
    /// result to help the compiler determine the correct types.
    public static func forceGn<Prev,Req>(_ request: Req, _ pcls: Prev.Type)
        -> HMRequestGenerator<Prev,Req>
    {
        return forceGn({_ in Observable.just(request)})
    }
    
    /// Create a request generator from a request object and a transformer.
    /// The transformer allows us to reuse request methods, albeit with minor
    /// modifications to the request object. E.g., for some requests we may
    /// want to set a fetchLimit under specific circumstances, or change the
    /// retry count.
    public static func forceGn<Prev,Req>(_ request: Req,
                                         _ transform: HMTransformer<Req>?,
                                         _ pcls: Prev.Type)
        -> HMRequestGenerator<Prev,Req>
    {
        return forceGn({_ in try transform?(request) ?? .just(request)})
    }
    
    private init() {}
}
