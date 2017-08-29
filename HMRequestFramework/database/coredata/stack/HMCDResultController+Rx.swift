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
    /// - Parameter cls: The PO class type.
    /// - Throws: Exception if the stream cannot be started.
    public func startStream<PO>(_ cls: PO.Type) -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        let base = self.base
        
        return Observable<Void>
            .create({
                base.deleteCache()
                
                do {
                    try base.startStream()
                    $0.onNext(())
                    $0.onCompleted()
                } catch let e {
                    $0.onError(e)
                }
                
                return Disposables.create()
            })
            .flatMap({self.streamEvents(cls)})
    }
    
    /// Get an Observable stream that emits DB events. Convert all objects into
    /// their PureObject forms.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: An Observable instance.
    private func streamEvents<PO>(_ cls: PO.Type) -> Observable<HMCDEvent<PO>> where
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
            .observeOn(MainScheduler.instance)
    }
}
