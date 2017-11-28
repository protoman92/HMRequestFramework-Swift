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
}
