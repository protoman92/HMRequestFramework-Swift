//
//  HMCDResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// The result processors below provide coupling between NSManagedObject subtype
/// and the specific data type we are trying to get.

public typealias HMCDTypedResultProcessor<Res: HMCDPureObjectType> =
    HMResultProcessor<Res.CDClass,Res>

/// Common CoreData result processors.
public final class HMCDResultProcessors {
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectProcessor<PO>()
        -> HMCDTypedResultProcessor<PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return {Observable.just($0.asPureObject()).map(Try.success)}
    }
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Parameter cls: The PureObject class type.
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectProcessor<PO>(_ cls: PO.Type)
        -> HMCDTypedResultProcessor<PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return pureObjectProcessor()
    }
    
    private init() {}
}
