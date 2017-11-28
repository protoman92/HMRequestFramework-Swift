//
//  HMTransforms.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/21/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

/// Utility class for HMTransform.
public final class HMTransforms {
    
    /// Sequentially apply some transformers to a value.
    ///
    /// - Parameters:
    ///   - value: An A instance.
    ///   - transforms: A Sequence of transformers.
    /// - Returns: An Observable instance.
    public static func applyTransformers<A>(_ value: A, _ transforms: [HMTransform<A>])
        -> Observable<A>
    {
        var chain = Observable.just(value)
        
        for transform in transforms {
            chain = chain.flatMap({try transform($0)})
        }
        
        return chain
    }
    
    private init() {}
}
