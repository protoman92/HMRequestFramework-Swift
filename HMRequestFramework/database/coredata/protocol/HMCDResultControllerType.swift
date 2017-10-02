//
//  HMCDResultControllerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 2/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle FRC-related
/// operations.
public protocol HMCDResultControllerType: HMCDTypealiasType, ReactiveCompatible {
    typealias Delegate = HMCDResultControllerDelegate
    typealias DBEvent = Delegate.DBEvent
    typealias Result = Delegate.Result
    
    typealias ChangeType = Delegate.ChangeType
    typealias Controller = Delegate.Controller
    typealias SectionInfo = Delegate.SectionInfo
    
    func didChangeContent<O>(_ controller: Controller, _ obs: O) where
        O: ObserverType, O.E == DBEvent
    
    func willChangeContent<O>(_ controller: Controller, _ obs: O) where
        O: ObserverType, O.E == DBEvent
    
    func didChangeObject<O>(_ controller: Controller,
                            _ object: Any,
                            _ oldIndex: IndexPath?,
                            _ changeType: ChangeType,
                            _ newIndex: IndexPath?,
                            _ obs: O) where
        O: ObserverType, O.E == DBEvent
    
    func didChangeSection<O>(_ controller: Controller,
                             _ sectionInfo: SectionInfo,
                             _ index: Int,
                             _ changeType: ChangeType,
                             _ obs: O) where
        O: ObserverType, O.E == DBEvent
}

public extension HMCDResultControllerType {
    
    /// Get a DB change Event from the associated result controller.
    ///
    /// - Parameter controller: A Controller instance.
    /// - Returns: An Event instance.
    func dbLevel(_ controller: Controller,
                 _ mapper: (DBLevel<Any>) -> DBEvent) -> DBEvent {
        return DBEvent.dbLevel(controller.sections,
                               controller.fetchedObjects,
                               controller.fetchRequest.fetchLimit,
                               mapper)
    }
}

public extension Reactive where Base: HMCDResultControllerType {
    /// Start events stream and observe the process.
    ///
    /// - Parameter obs: An ObserverType instance.
    /// - Return: A Disposable instance.
    /// - Throws: Exception if the stream cannot be started.
    private func startDBStream<O>(_ frc: Base.Controller, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Base.DBEvent
    {
        Preconditions.checkNotRunningOnMainThread(frc.fetchRequest)
        
        let base = self.base
        
        let delegate = Base.Delegate.builder()
            .with(didChangeContent: {base.didChangeContent($0, obs)})
            .with(willChangeContent: {base.willChangeContent($0, obs)})
            .with(didChangeObject: {base.didChangeObject($0.0, $0.1, $0.2, $0.3, $0.4, obs)})
            .with(didChangeSection: {base.didChangeSection($0.0, $0.1, $0.2, $0.3, obs)})
            .build()
        
        frc.delegate = delegate
        
        obs.onNext(Base.DBEvent.willLoad)
        
        do {
            try frc.performFetch()
            obs.onNext(base.dbLevel(frc, Base.DBEvent.didLoad))
        } catch let e {
            obs.onNext(base.dbLevel(frc, Base.DBEvent.didLoad))
            obs.onError(e)
        }
        
        return Disposables.create(with: delegate.removeCallbacks)
    }
    
    /// Start the stream and convert all event data to PO.
    ///
    /// - Parameter:
    ///   - context: A Context instance.
    ///   - request: A HMCDFetchedResultRequestType instance.
    ///   - cls: The PO class type.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the stream cannot be started.
    func startDBStream<PO>(_ context: Base.Context,
                           _ request: HMCDFetchedResultRequestType,
                           _ cls: PO.Type) -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        do {
            let fetchRequest = try request.untypedFetchRequest()
            let sectionName = request.frcSectionName()
            let cacheName = request.frcCacheName()
            let qos = request.frcDefautQoS() ?? .userInitiated
            
            let frc = Base.Controller(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: sectionName,
                cacheName: cacheName
            )
            
            return Observable<Base.DBEvent>
                .create({obs in
                    if let cacheName = cacheName {
                        Base.Controller.deleteCache(withName: cacheName)
                    }
                
                    return self.startDBStream(frc, obs)
                })
                .subscribeOnConcurrent(qos: qos)
                .observeOnConcurrent(qos: qos)
                
                // All events' objects will be implicitly converted to PO. For e.g.,
                // for a section change event, the underlying HMCDEvent<Any> will
                // be mapped to PO generics.
                .map({$0.cast(to: PO.CDClass.self)})
                .map({$0.map({$0.asPureObject()})})
                .doOnNext(Preconditions.checkNotRunningOnMainThread)
        } catch let e {
            return Observable.error(e)
        }
    }
}
