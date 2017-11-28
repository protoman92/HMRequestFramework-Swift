//
//  HMCDEvents.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/6/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxDataSources
import RxSwift
import SwiftUtilities

/// HMCDEvent utilities.
public final class HMCDEvents {
    
    /// Extract didLoad sections.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    public static func didLoadSections<PO>(_ event: Try<HMCDEvent<PO>>)
        -> [HMCDSection<PO>]
    {
        switch event {
        case .success(.didLoad(let change)): return change
        default: return []
        }
    }
    
    /// Extract didLoad sections.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    public static func didLoadAnimatedSections<PO>(_ event: Try<HMCDEvent<PO>>)
        -> [HMCDAnimatableSection<PO>] where
        PO: IdentifiableType & Equatable
    {
        return didLoadSections(event).map({$0.animated()})
    }
    
    private init() {}
}
