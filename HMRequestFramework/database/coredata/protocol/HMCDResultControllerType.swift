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
public protocol HMCDResultControllerType: HMCDTypealiasType {
    typealias Delegate = HMCDResultControllerDelegate
    typealias DBEvent = Delegate.DBEvent
    typealias Result = Delegate.Result
    
    typealias ChangeType = Delegate.ChangeType
    typealias Controller = Delegate.Controller
    typealias SectionInfo = Delegate.SectionInfo
    
    typealias FRCRequest = HMCDFetchedResultRequestType
    
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

