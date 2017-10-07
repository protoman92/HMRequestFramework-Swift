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
    
    /// Start the stream and convert all event data to PO.
    ///
    /// - Parameter:
    ///   - request: A HMCDFetchedResultRequestType instance.
    ///   - cls: The PO class type.
    ///   - defaultQoS: The QoSClass instance to perform work on.
    /// - Return: An Observable instance.
    /// - Throws: Exception if the stream cannot be started.
    public func startDBStream<PO>(_ request: HMCDFetchedResultRequestType,
                                  _ cls: PO.Type,
                                  _ defaultQoS: DispatchQoS.QoSClass)
        -> Observable<HMCDEvent<PO>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return startDBStream(base.mainObjectContext(), request, cls, defaultQoS)
    }
}
