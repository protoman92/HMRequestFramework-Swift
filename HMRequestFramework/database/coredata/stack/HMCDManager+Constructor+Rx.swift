//
//  HMCDManager+Constructor+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 28/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

extension HMCDManager {
    
    /// Construct a CoreData object from a data object.
    ///
    /// This method is useful when we have two parallel classes - one inheriting
    /// from NSManagedObject, while the other simply contains properties
    /// identical to the former (so that we can avoid hidden pitfalls of
    /// using NSManagedObject directly).
    ///
    /// We can pass the data object to this method, and it will create for
    /// us a NSManagedObject instance with the same properties. We can then
    /// save this to the local DB.
    ///
    /// - Parameter:
    ///   - context: A Context instance.
    ///   - pureObj: A PO instance.
    /// - Returns: A PO.CDClass object.
    /// - Throws: Exception if the construction fails.
    func constructUnsafely<PO>(_ context: Context, _ pureObj: PO) throws -> PO.CDClass where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return try PO.CDClass.builder(context).with(pureObject: pureObj).build()
    }
    
    /// Construct CoreData objects from multiple pure objects.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjs: A Sequence of PO.
    /// - Returns: An Array of PO.CDClass.
    /// - Throws: Exception if the construction fails.
    func constructUnsafely<PO,S>(_ context: Context,
                                 _ pureObjs: S) throws
        -> [PO.CDClass] where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Element == PO
    {
        return try pureObjs.map({try self.constructUnsafely(context, $0)})
    }
}

public extension HMCDManager {
    
    /// Construct CoreData objects from multiple pure objects and observe
    /// the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjs: A Sequence of PO.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func construct<PO,S,O>(_ context: Context,
                           _ pureObjs: S,
                           _ obs: O) -> Disposable where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Element == PO,
        O: ObserverType, O.E == [PO.CDClass]
    {
        Preconditions.checkNotRunningOnMainThread(pureObjs)
        
        do {
            let data = try self.constructUnsafely(context, pureObjs)
            obs.onNext(data)
            obs.onCompleted()
        } catch let e {
            obs.onError(e)
        }
        
        return Disposables.create()
    }
}

public extension Reactive where Base == HMCDManager {
    
    /// Construct CoreData objects from multiple pure objects.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjs: A Sequence of PO.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the construction fails.
    public func construct<PO,S>(_ context: HMCDManager.Context, _ pureObjs: S)
        -> Observable<[PO.CDClass]> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Element == PO
    {
        return Observable.create({self.base.construct(context, pureObjs, $0)})
    }
}
