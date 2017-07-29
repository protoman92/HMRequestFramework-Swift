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
    
    /// Apply registered transform middlewares.
    ///
    /// - Parameter result: The original object to be applied on.
    /// - Returns: An Observable instance.
    func applyTransformMiddlewares(_ result: Target) -> Observable<Target>
    
    /// Apply registered side effect middlewares.
    ///
    /// - Parameter result: The original object to be applied on.
    func applySideEffectMiddlewares(_ result: Target)
}
