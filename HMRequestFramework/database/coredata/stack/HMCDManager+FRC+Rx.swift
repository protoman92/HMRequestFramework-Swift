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

public extension HMCDManager {
    
    /// Get a fetched result controller for a fetch request.
    ///
    /// - Parameters:
    ///   - request: A HMCDFetchedResultRequestType instance.
    ///   - cls: The Val class type.
    /// - Returns: A NSFetchedResultsController instance.
    func getFRCForRequest<Val>(_ request: HMCDFetchedResultRequestType,
                               _ cls: Val.Type) throws
        -> NSFetchedResultsController<Val>
    {
        let fetchRequest = try request.fetchRequest(cls)
        let sectionName = request.frcSectionName()
        let cacheName = request.frcCacheName()
        
        // Since all save and fetch requests pass through the main context, we
        // can set it as the target context for the FRC.
        return NSFetchedResultsController<Val>(
            fetchRequest: fetchRequest,
            managedObjectContext: mainObjectContext(),
            sectionNameKeyPath: sectionName,
            cacheName: cacheName
        )
    }
    
    /// Get the FRC wrapper that also implements FRC delegate methods.
    ///
    /// - Parameters request: A HMCDFetchedResultRequestType instance.
    /// - Returns: A HMCDResultController instance.
    func getFRCWrapperForRequest(_ request: HMCDFetchedResultRequestType) throws
        -> HMCDResultController
    {
        let frc = try getFRCForRequest(request, HMCDResultController.Result.self)
        return HMCDResultController.builder().with(frc: frc).build()
    }
}
