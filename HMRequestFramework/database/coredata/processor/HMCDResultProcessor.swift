//
//  HMCDResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Common CoreData result processors.
public final class HMCDResultProcessors {
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectPs<PO>() -> HMResultProcessor<PO.CDClass,PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return {
            do {
                return try Observable.just(Try.success($0.asPureObject()))
            } catch let e {
                return Observable.just(Try.failure(e))
            }
        }
    }
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Parameter cls: The PureObject class type.
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectPs<PO>(_ cls: PO.Type) -> HMResultProcessor<PO.CDClass,PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return pureObjectPs()
    }
    
    private init() {}
}
