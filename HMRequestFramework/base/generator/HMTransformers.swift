//
//  HMTransformers.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/21/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

/// Utility class for HMTransformer.
public final class HMTransformers {
    
    /// Sequentially apply some transformers to a value.
    ///
    /// - Parameters:
    ///   - value: An A instance.
    ///   - transforms: A Sequence of transformers.
    /// - Returns: An Observable instance.
    public static func applyTransformers<A,S>(_ value: A, _ transforms: S)
        -> Observable<A> where
        S: Sequence, S.Iterator.Element == HMTransformer<A>
    {
        var chain = Observable.just(value)
        
        for transform in transforms {
            chain = chain.flatMap({try transform($0)})
        }
        
        return chain
    }
    
    private init() {}
}
