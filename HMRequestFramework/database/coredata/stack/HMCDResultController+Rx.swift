//
//  HMCDResultController+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

extension Reactive where Base: HMCDResultController {
    
    /// Start the stream.
    ///
    /// - Throws: Exception if the stream cannot be started.
    public func startStream() throws {
        try base.controller().performFetch()
    }
    
    /// Get an Observable stream that emits DB events. Convert all objects into
    /// their PureObject forms.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: An Observable instance.
    public func streamEvents<PO>(_ cls: PO.Type) -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return base.eventObservable()
            
            // All events' objects will be implicitly converted to PO. For e.g.,
            // for a section change event, the underlying HMCDEvent<Any> will
            // be mapped to PO generics.
            .map({$0.cast(to: PO.CDClass.self)})
            .map({$0.map({$0.asPureObject()})})
            .takeUntil(deallocated)
    }
}
