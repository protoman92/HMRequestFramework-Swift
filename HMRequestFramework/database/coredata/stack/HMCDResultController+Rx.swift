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
    
    /// Get an Observable stream that only emits pure objects of some type.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: An Observable instance.
    public func stream<PO>(_ cls: PO.Type) -> Observable<[PO]> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return base.cdSubject
            .map({$0.flatMap({$0 as? PO.CDClass})})
            .map({$0.map({$0.asPureObject()})})
            .takeUntil(deallocated)
    }
}
