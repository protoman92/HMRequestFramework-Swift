//
//  HMCDResultController+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

extension Reactive where Base: HMCDResultController {
    
    /// Start events stream and observe the process.
    ///
    /// - Parameter obs: An ObserverType instance.
    /// - Throws: Exception if the stream cannot be started.
    private func startStream<O>(_ obs: O) where O: ObserverType, O.E == Void {
        base.deleteCache()
        let controller = base.controller()
        let dbLevelObserver = base.dbLevelObserver()
        dbLevelObserver.onNext(Base.Event.willLoad)
        
        do {
            try controller.performFetch()
            obs.onNext(())
            obs.onCompleted()
        } catch let e {
            obs.onError(e)
        }
        
        dbLevelObserver.onNext(base.dbLevel(controller, Base.Event.didLoad))
    }
    
    /// Start the stream.
    ///
    /// - Parameter cls: The PO class type.
    /// - Throws: Exception if the stream cannot be started.
    public func startStream<PO>(_ cls: PO.Type) -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return Observable<Void>
            .create({
                self.startStream($0)
                return Disposables.create()
            })
            
            // If we subscribe on a background thread, there might be unexpected
            // behaviors due to different threading.
            .subscribeOn(MainScheduler.instance)
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
