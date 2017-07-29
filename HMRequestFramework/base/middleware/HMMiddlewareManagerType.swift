//
//  HMMiddlewareManagerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

public protocol HMMiddlewareManagerType {
    associatedtype Target
    
    /// Get the middlewares to apply.
    ///
    /// - Returns: An Array of HMRequestMiddleware.
    func middlewares() -> [HMRequestMiddleware<Target>]
}

public extension HMMiddlewareManagerType {
    
    /// Sequentially apply a Sequence of middlewares.
    ///
    /// - Parameters:
    ///   - original: The original object to be applied on.
    ///   - middlewares: A Sequence of middlewares.
    /// - Returns: An Observable instance.
    func applyMiddlewares<S>(_ original: Try<Target>, _ middlewares: S)
        -> Observable<Try<Target>> where
        S: Sequence, S.Iterator.Element == HMRequestMiddleware<Target>
    {
        let middlewares = middlewares.map(eq)
        
        if let first = middlewares.first {
            do {
                var chain = try first(original).catchErrorJustReturn(Try.failure)
                
                for (index, middleware) in middlewares.enumerated() {
                    if (index > 0) {
                        chain = chain.flatMap({
                            try middleware($0).catchErrorJustReturn(Try.failure)
                        })
                    }
                }
                
                return chain
            } catch let e {
                return Observable.just(Try.failure(e))
            }
        } else {
            return Observable.just(original)
        }
    }
    
    /// Apply registered middlewares.
    ///
    /// - Parameter original: The original object to be applied on.
    /// - Returns: An Observable instance.
    func applyMiddlewares(_ original: Try<Target>) -> Observable<Try<Target>> {
        let middlewares = self.middlewares()
        
        return applyMiddlewares(original, middlewares)
            .ifEmpty(default: original)
            .catchErrorJustReturn(Try.failure)
    }
}
