//
//  HMRequestPerformers.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/1/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Utility class for request performer.
public final class HMRequestPerformers {
    
    /// Get a performer that does no transformation.
    ///
    /// - Returns: A HMRequestPerformer instance.
    public static func eqPerformer<Req>() -> HMRequestPerformer<Req,Req> {
        return {Observable.just(Try.success($0))}
    }
    
    /// Get a performer that does no transformation.
    ///
    /// - Parameter cls: The Req class type.
    /// - Returns: A HMRequestPerform instance.
    public static func eqPerformer<Req>(_ cls: Req.Type) -> HMRequestPerformer<Req,Req> {
        return eqPerformer()
    }
    
    private init() {}
}
