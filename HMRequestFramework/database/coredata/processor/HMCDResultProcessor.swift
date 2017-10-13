//
//  HMCDResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Common CoreData result processors.
public final class HMCDResultProcessors {
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectPs<PO>() -> HMResultProcessor<PO.CDClass,PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return {Observable.just(try $0.asPureObject()).map(Try.success)}
    }
    
    /// Result processor that converts a CoreData object into a Pure Object.
    ///
    /// - Parameter cls: The PureObject class type.
    /// - Returns: A HMCDTypedResultProcessor instance.
    public static func pureObjectPs<PO>(_ cls: PO.Type) -> HMResultProcessor<PO.CDClass,PO> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return pureObjectPs()
    }
    
    private init() {}
}
