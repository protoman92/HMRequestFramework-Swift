//
//  HMCDManager+FRC+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 23/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift
import SwiftUtilities

extension HMCDManager: HMCDResultControllerType {
    public typealias DBEvent = HMCDResultControllerType.DBEvent
    
    public func didChangeContent<O>(_ controller: Controller, _ obs: O) where
        O: ObserverType, O.E == DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        obs.onNext(self.dbLevel(controller, DBEvent.didLoad))
        obs.onNext(DBEvent.didChange)
    }
    
    public func willChangeContent<O>(_ controller: Controller, _ obs: O) where
        O: ObserverType, O.E == DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        obs.onNext(DBEvent.willLoad)
        obs.onNext(DBEvent.willChange)
    }
    
    public func didChangeObject<O>(_ controller: Controller,
                                   _ object: Any,
                                   _ oldIndex: IndexPath?,
                                   _ changeType: ChangeType,
                                   _ newIndex: IndexPath?,
                                   _ obs: O) where
        O: ObserverType, O.E == DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(object)
        obs.onNext(DBEvent.objectLevel(changeType, object, oldIndex, newIndex))
    }
    
    public func didChangeSection<O>(_ controller: Controller,
                                    _ sectionInfo: SectionInfo,
                                    _ index: Int,
                                    _ changeType: ChangeType,
                                    _ obs: O) where
        O: ObserverType, O.E == DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(sectionInfo)
        obs.onNext(DBEvent.sectionLevel(changeType, sectionInfo, index))
    }
}

public extension Reactive where Base == HMCDManager {
    
    /// Start events stream and observe the process.
    ///
    /// - Parameter:
    ///   - frc: A Controller instance.
    ///   - request: A FRCRequest instance.
    ///   - obs: An ObserverType instance.
    /// - Return: A Disposable instance.
    /// - Throws: Exception if the stream cannot be started.
    private func startDBStream<O>(_ frc: HMCDManager.Controller,
                                  _ request: HMCDManager.FRCRequest,
                                  _ obs: O) -> Disposable where
        O: ObserverType, O.E == HMCDManager.DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(frc.fetchRequest)
        
        let base = self.base
        
        let delegate = HMCDManager.Delegate.builder()
            .with(didChangeContent: {base.didChangeContent($0, obs)})
            .with(willChangeContent: {base.willChangeContent($0, obs)})
            .with(didChangeObject: {base.didChangeObject($0.0, $0.1, $0.2, $0.3, $0.4, obs)})
            .with(didChangeSection: {base.didChangeSection($0.0, $0.1, $0.2, $0.3, obs)})
            .build()
        
        frc.delegate = delegate
        
        obs.onNext(HMCDManager.DBEvent.willLoad)
        
        let context = frc.managedObjectContext
        let operationMode = request.operationMode()
        
        base.performOperation(context, .perform, operationMode, {
            do {
                try frc.performFetch()
                obs.onNext(base.dbLevel(frc, HMCDManager.DBEvent.didLoad))
            } catch let e {
                obs.onNext(base.dbLevel(frc, HMCDManager.DBEvent.didLoad))
                obs.onError(e)
            }
        })
        
        return Disposables.create(with: delegate.removeCallbacks)
    }
    
    /// Start the stream and convert all event data to PO.
    ///
    /// - Parameter:
    ///   - context: A Context instance.
    ///   - request: A FRCRequest instance.
    ///   - cls: The PO class type.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the stream cannot be started.
    func startDBStream<PO>(_ context: HMCDManager.Context,
                           _ request: HMCDManager.FRCRequest,
                           _ cls: PO.Type,
                           _ qos: DispatchQoS.QoSClass)
        -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        do {
            let fetchRequest = try request.untypedFetchRequest()
            let sectionName = request.frcSectionName()
            let cacheName = request.frcCacheName()
            
            let frc = HMCDManager.Controller(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: sectionName,
                cacheName: cacheName
            )
            
            return Observable<Base.DBEvent>
                .create({obs in
                    if let cacheName = cacheName {
                        HMCDManager.Controller.deleteCache(withName: cacheName)
                    }
                    
                    return self.startDBStream(frc, request, obs)
                })
                .subscribeOnConcurrent(qos: qos)
                
                // All events' objects will be implicitly converted to PO. For e.g.,
                // for a section change event, the underlying HMCDEvent<Any> will
                // be mapped to PO generics.
                .map({$0.cast(to: PO.CDClass.self)})
                .map({$0.map({try $0.asPureObject()})})
                .doOnNext(Preconditions.checkNotRunningOnMainThread)
        } catch let e {
            return Observable.error(e)
        }
    }
    
    /// Start the stream and convert all event data to PO.
    ///
    /// - Parameter:
    ///   - request: A FRCRequest instance.
    ///   - cls: The PO class type.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the stream cannot be started.
    public func startDBStream<PO>(_ request: HMCDManager.FRCRequest,
                                  _ cls: PO.Type,
                                  _ qos: DispatchQoS.QoSClass)
        -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return startDBStream(base.mainObjectContext(), request, cls, qos)
    }
}
