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

extension HMCDManager: HMCDResultControllerType {}

public extension Reactive where Base == HMCDManager {
    
    /// Start events stream and observe the process.
    ///
    /// - Parameter:
    ///   - frc: A Controller instance.
    ///   - request: A FRCRequest instance.
    ///   - obs: An ObserverType instance.
    /// - Return: A Disposable instance.
    /// - Throws: Exception if the stream cannot be started.
    private func startDBStream(_ frc: HMCDManager.Controller,
                               _ request: HMCDManager.FRCRequest,
                               _ obs: AnyObserver<HMCDManager.DBEvent>) -> Disposable {
        let base = self.base
        
        let delegate = HMCDManager.Delegate(obs)
        frc.delegate = delegate
        obs.onNext(HMCDManager.DBEvent.willLoad)
        
        let context = frc.managedObjectContext
        let operationMode = request.operationMode()
        
        base.performOperation(context, .perform, operationMode, {[weak frc] in
            guard let frc = frc else { return }
            
            do {
                try frc.performFetch()
                obs.onNext(delegate.dbLevel(frc, HMCDManager.DBEvent.didLoad))
            } catch let e {
                obs.onNext(delegate.dbLevel(frc, HMCDManager.DBEvent.didLoad))
                obs.onError(e)
            }
        })
        
        return Disposables.create(with: {delegate.deinitialize()})
    }
    
    /// Start the stream and emit base DB events.
    ///
    /// - Parameter:
    ///   - context: A Context instance.
    ///   - request: A FRCRequest instance.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Return: An Observable instance.
    func startDBStream(_ context: HMCDManager.Context,
                       _ request: HMCDManager.FRCRequest,
                       _ qos: DispatchQoS.QoSClass)
        -> Observable<HMCDManager.DBEvent>
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
            
            return Observable<HMCDManager.DBEvent>
                .create({obs in
                    if let cacheName = cacheName {
                        HMCDManager.Controller.deleteCache(withName: cacheName)
                    }
                    
                    return self.startDBStream(frc, request, obs)
                })
                .subscribeOnConcurrent(qos: qos)
        } catch let e {
            return Observable.error(e)
        }
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
        return startDBStream(context, request, qos)
            .map({$0.cast(to: PO.CDClass.self).map({try $0.asPureObject()})})
    }
    
    /// Start the stream and emit base DB events.
    ///
    /// - Parameter:
    ///   - request: A FRCRequest instance.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Return: An Observable instance.
    public func startDBStream(_ request: HMCDManager.FRCRequest,
                              _ qos: DispatchQoS.QoSClass)
        -> Observable<HMCDManager.DBEvent>
    {
        return startDBStream(base.mainObjectContext(), request, qos)
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
