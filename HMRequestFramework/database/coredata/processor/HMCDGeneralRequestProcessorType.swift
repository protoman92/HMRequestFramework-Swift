//
//  HMCDGeneralRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle common CoreData
/// requests.
public protocol HMCDGeneralRequestProcessorType {
    
    /// Fetch all data of a type from DB, then convert them to pure objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PureObject class type.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func fetchAllDataFromDB<Prev,PO,S>(_ previous: Try<Prev>,
                                       _ cls: PO.Type,
                                       _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<HMCDRequest>
    
    /// Save some data to memory by constructing them and then saving the
    /// resulting managed objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func saveToMemory<PO,S>(_ previous: Try<[PO]>, _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<HMCDRequest>
    
    /// Reset the CoreData stack and wipe DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func resetStack<Prev,S>(_ previous: Try<Prev>, _ transforms: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransformer<HMCDRequest>
    
    /// Perform an upsert operation with some upsertable data.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func upsertInMemory<U,S>(_ previous: Try<[U]>, _ transforms: S)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == HMTransformer<HMCDRequest>
    
    /// Perform an upsert operation with some pure objects by constructing
    /// managed objects and then upserting them afterwards.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func upsertInMemory<PO,S>(_ previous: Try<[PO]>, _ transform: S)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<HMCDRequest>
    
    /// Persist all data to DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transform: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func persistToDB<Prev,S>(_ previous: Try<Prev>, _ transform: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransformer<HMCDRequest>
}

/// Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                            _ cls: PO.Type,
                                            _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchAllDataFromDB(previous, cls, transforms)
    }
    
    public func saveToMemory<PO>(_ previous: Try<[PO]>,
                                 _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return saveToMemory(previous, transforms)
    }
    
    public func resetStack<Prev>(_ previous: Try<Prev>,
                                 _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return resetStack(previous, transforms)
    }
    
    public func upsertInMemory<U>(_ previous: Try<[U]>,
                                  _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    {
        return upsertInMemory(previous, transforms)
    }
    
    public func upsertInMemory<PO>(_ previous: Try<[PO]>,
                                   _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return upsertInMemory(previous, transforms)
    }
    
    public func persistToDB<Prev>(_ previous: Try<Prev>,
                                  _ transforms: HMTransformer<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return persistToDB(previous, transforms)
    }
}
