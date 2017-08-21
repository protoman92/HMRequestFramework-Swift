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
    typealias Req = HMCDRequest
    
    /// Fetch all data of a type from DB, then convert them to pure objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transform: A Request transformer.
    ///   - cls: The PureObject class type.
    /// - Returns: An Observable instance.
    func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                     _ transform: HMTransformer<Req>?,
                                     _ cls: PO.Type)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    
    /// Save some data to memory by constructing them and then saving the
    /// resulting managed objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transform: A Request transformer.
    /// - Returns: An Observable instance.
    func saveToMemory<PO>(_ previous: Try<[PO]>,
                          _ transform: HMTransformer<Req>?)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    
    /// Perform an upsert operation with some upsertable data.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transform: A Request transformer.
    /// - Returns: An Observable instance.
    func upsertInMemory<U>(_ previous: Try<[U]>, _ transform: HMTransformer<Req>?)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType,
        U: HMCDUpsertableType
    
    /// Perform an upsert operation with some pure objects by constructing
    /// managed objects and then upserting them afterwards.
    ///
    /// - Parameters:
    ///   - previous: A Sequence of PO.
    ///   - transform: A Request transformer.
    /// - Returns: An Observable instance.
    func upsertInMemory<PO>(_ previous: [PO], _ transform: HMTransformer<Req>?)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    
    /// Persist all data to DB.
    ///
    /// - Parameter previous: The result of the previous request.
    /// - Returns: An Observable instance.
    func persistToDB<Prev>(_ previous: Try<Prev>, _ transform: HMTransformer<Req>?)
        -> Observable<Try<Void>>
}
