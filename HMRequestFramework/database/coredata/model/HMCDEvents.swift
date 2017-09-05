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
    
    /// Extract didLoad event. Be wary that this Observable does not catch
    /// error.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    private static func didLoad<PO>(_ event: Try<HMCDEvent<PO>>) -> Observable<DBLevel<PO>> {
        return Observable.just(event)
            .map({try $0.getOrThrow()})
            .flatMap({event -> Observable<DBLevel<PO>> in
                switch event {
                case .didLoad(let change): return .just(change)
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
        return didLoad(event)
            .map({$0.sections})
            .map({$0.map({$0.animated()})})
            .catchErrorJustReturn([HMCDAnimatableSection<PO>]())
    }
    
    /// Extract didLoad objects.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Observable instance.
    public static func didLoadObjects<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[PO]>
    {
        return didLoad(event).map({$0.objects}).catchErrorJustReturn([PO]())
    }
    
    private init() {}
}
