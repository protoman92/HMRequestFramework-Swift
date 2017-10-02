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
    
    /// Extract didLoad event.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    private static func didLoad<PO>(_ event: Try<HMCDEvent<PO>>) -> Observable<DBLevel<PO>> {
        return Observable.just(event)
            .flatMap({event -> Observable<DBLevel<PO>> in
                switch event {
                case .success(.didLoad(let change)): return .just(change)
                default: return .empty()
                }
            })
    }
    
    /// Extract didLoad sections.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    public static func didLoadSections<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[HMCDAnimatableSection<PO>]> where
        PO: IdentifiableType & Equatable
    {
        return didLoad(event).map({$0})
            .map({$0.map({$0.animated()})})
            .catchErrorJustReturn([HMCDAnimatableSection<PO>]())
    }
    
    private init() {}
}
