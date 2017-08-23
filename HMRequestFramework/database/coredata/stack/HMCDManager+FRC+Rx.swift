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
    ///   - request: A NSFetchRequest instance.
    ///   - sectionName: A String value of the sectionName.
    ///   - cacheName: A String value of the cache name.
    /// - Returns: A NSFetchedResultsController instance.
    func getFRCForRequest<Val>(_ request: NSFetchRequest<Val>,
                               _ sectionName: String?,
                               _ cacheName: String?) -> NSFetchedResultsController<Val> {
        // Since all save and fetch requests pass through the main context, we
        // can set it as the target context for the FRC.
        return NSFetchedResultsController<Val>(
            fetchRequest: request,
            managedObjectContext: mainContext,
            sectionNameKeyPath: sectionName,
            cacheName: cacheName
        )
    }
    
    /// Get the FRC wrapper that also implements FRC delegate methods.
    ///
    /// - Parameters:
    ///   - request: A NSFetchRequest instance.
    ///   - sectionName: A String value of the sectionName.
    ///   - cacheName: A String value of the cache name.
    /// - Returns: A HMCDFetchedResultController instance.
    func getFRCWrapperForRequest(_ request: NSFetchRequest<NSFetchRequestResult>,
                                 _ sectionName: String?,
                                 _ cacheName: String?) -> HMCDFetchedResultController {
        let frc = getFRCForRequest(request, sectionName, cacheName)
        return HMCDFetchedResultController(frc)
    }
}
