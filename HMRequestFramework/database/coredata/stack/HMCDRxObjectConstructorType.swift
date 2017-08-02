//
//  HMCDRxObjectConstructorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/2/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift

public protocol HMCDRxObjectConstructorType: HMCDObjectConstructorType {}

public extension HMCDRxObjectConstructorType {
    
    /// Construct CoreData objects from multiple pure objects and observe
    /// the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - pureObjs: A Sequence of PO.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the construction fails.
    public func construct<PO,S,O>(_ context: NSManagedObjectContext,
                                  _ pureObjs: S,
                                  _ obs: O) where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Iterator.Element == PO,
        O: ObserverType, O.E == [PO.CDClass]
    {
        context.performAndWait {
            do {
                let data = try self.constructUnsafely(context, pureObjs)
                obs.onNext(data)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}
