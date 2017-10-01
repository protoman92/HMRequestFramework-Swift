//
//  HMCDResultController+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

extension Reactive where Base: HMCDResultController {
    
    /// Start events stream and observe the process.
    ///
    /// - Parameter obs: An ObserverType instance.
    /// - Return: A Disposable instance.
    /// - Throws: Exception if the stream cannot be started.
    private func startStream<O>(_ obs: O) -> Disposable where O: ObserverType, O.E == Void {
        base.deleteCache()
        let controller = base.controller()
        let dbLevelObserver = base.dbLevelObserver()
        
        // The db level observer's events are observed on a queue, so both
        // willLoad and didLoad will be delivered.
        dbLevelObserver.onNext(Base.Event.willLoad)
        
        do {
            try controller.performFetch()
            obs.onNext(())
            obs.onCompleted()
        } catch let e {
            obs.onError(e)
        }
        
        
        dbLevelObserver.onNext(base.dbLevel(controller, Base.Event.didLoad))
        return Disposables.create()
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
        let qos = base.qualityOfService
        
        return Observable<Void>
            .create(self.startStream)
            .subscribeOn(qos: qos)
            .observeOn(qos: qos)
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
        let qos = base.qualityOfService
        
        return base.eventObservable()
            .observeOn(qos: qos)
            
            // All events' objects will be implicitly converted to PO. For e.g.,
            // for a section change event, the underlying HMCDEvent<Any> will
            // be mapped to PO generics.
            .map({$0.cast(to: PO.CDClass.self)})
            .map({$0.map({$0.asPureObject()})})
            .takeUntil(deallocated)
    }
}
