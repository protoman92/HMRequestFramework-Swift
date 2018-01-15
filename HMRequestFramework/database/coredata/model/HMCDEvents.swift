//
//  HMCDEvents.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/6/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Differentiator
import RxSwift
import SwiftUtilities

/// HMCDEvent utilities.
public final class HMCDEvents {
    
    /// Extract didLoad sections.
    ///
    /// - Parameter event: A HMCDEvent instance.
    /// - Returns: An Array of HMCDSection.
    static func didLoadSections<PO>(_ event: HMCDEvent<PO>) -> Observable<[HMCDSection<PO>]> {
        switch event {
        case .didLoad(let change): return .just(change)
        default: return .empty()
        }
    }
    
    /// Extract didLoad sections.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Array of HMCDSection.
    public static func didLoadSections<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[HMCDSection<PO>]>
    {
        /// BEWARE: COMMENTED CODE BELOW LEADS TO MEMORY LEAK. This could be a
        /// Swift Enum bug.
//        switch event {
//        case .success(.didLoad(let change)): return .just(change)
//        default: return .empty()
//        }
        switch event {
        case .success(let event): return didLoadSections(event)
        case .failure: return .empty()
        }
    }
    
    /// Extract didLoad sections and convert each to a animatable section.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Array of HMCDAnimatableSection.
    public static func didLoadAnimatableSections<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[HMCDAnimatableSection<PO>]> where
        PO: IdentifiableType & Equatable
    {
        return didLoadSections(event).map({$0.map({$0.animatableSection()})})
    }
    
    /// Extract didLoad sections and convert each to a section model.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Array of SectionModel.
    public static func didLoadReloadModels<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[SectionModel<String,PO>]>
    {
        return didLoadSections(event).map({$0.map({$0.reloadModel()})})
    }
    
    
    /// Extract didLoad sections and convert each to a animatable section model.
    ///
    /// - Parameter event: A Try HMCDEvent instance.
    /// - Returns: An Array of AnimatableSectionModel.
    public static func didLoadAnimatableModels<PO>(_ event: Try<HMCDEvent<PO>>)
        -> Observable<[AnimatableSectionModel<String,PO>]> where
        PO: IdentifiableType & Equatable
    {
        return didLoadSections(event).map({$0.map({$0.animatableModel()})})
    }
    
    private init() {}
}
