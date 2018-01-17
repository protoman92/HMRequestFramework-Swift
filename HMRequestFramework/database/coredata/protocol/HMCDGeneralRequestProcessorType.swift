//
//  HMCDGeneralRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 21/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle common CoreData
/// requests.
public protocol HMCDGeneralRequestProcessorType {
    
    /// Fetch all data of a type from DB, then convert them to pure objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                     _ cls: PO.Type,
                                     _ qos: DispatchQoS.QoSClass,
                                     _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    
    /// Save some data to memory by constructing them and then saving the
    /// resulting managed objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - qos: The QosClass to be used for CD object construction.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func saveToMemory<PO>(_ previous: Try<[PO]>,
                          _ qos: DispatchQoS.QoSClass,
                          _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    
    /// Delete some data in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteInMemory<PO>(_ previous: Try<[PO]>,
                            _ qos: DispatchQoS.QoSClass,
                            _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType
    
    /// Delete all data of some entity name in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - entityName: A String value denoting the entity name.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteAllInMemory<Prev>(_ previous: Try<Prev>,
                                 _ entityName: String?,
                                 _ qos: DispatchQoS.QoSClass,
                                 _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<Void>>
    
    /// Reset the CoreData stack and wipe DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func resetStack<Prev>(_ previous: Try<Prev>,
                          _ qos: DispatchQoS.QoSClass,
                          _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<Void>>
    
    /// Perform an upsert operation with some upsertable data.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<U>(_ previous: Try<[U]>,
                           _ qos: DispatchQoS.QoSClass,
                           _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    
    /// Perform an upsert operation with some pure objects by constructing
    /// managed objects and then upserting them afterwards.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - qos: The QoSClass to be used for CD object construction.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<PO>(_ previous: Try<[PO]>,
                            _ qos: DispatchQoS.QoSClass,
                            _ transform: [HMTransform<HMCDRequest>])
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    
    /// Persist all data to DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transform: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func persistToDB<Prev>(_ previous: Try<Prev>,
                           _ qos: DispatchQoS.QoSClass,
                           _ transform: [HMTransform<HMCDRequest>])
        -> Observable<Try<Void>>
    
    /// Stream DB changes for some pure object type.
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func streamDBEvents<PO>(_ cls: PO.Type,
                            _ qos: DispatchQoS.QoSClass,
                            _ transforms: [HMTransform<HMCDRequest>])
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Get the predicate from some object properties for a fetch/delete
    /// operation.
    ///
    /// - Parameter:
    ///    - properties: A Dictionary of properties.
    ///    - joinMode: A NSCompoundPredicate.LogicalType instance.
    /// - Returns: A NSPredicate instance.
    private func predicateForProperties(_ properties: [String : [CVarArg]],
                                        _ joinMode: NSCompoundPredicate.LogicalType)
        -> NSPredicate
    {
        let predicates = properties.map({NSPredicate(format: "%K in %@", $0.0, $0.1)})
        return NSCompoundPredicate(type: joinMode, subpredicates: predicates)
    }
    
    /// Fetch all data that have some properties. These properties will be mapped
    /// into a series of predicates and joined together with AND.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - props: The properties to search for.
    ///   - predicateMode: A NSCompoundPredicate.LogicalType instance.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchWithProperties<Prev,PO,S>(_ previous: Try<Prev>,
                                               _ cls: PO.Type,
                                               _ props: [String : [CVarArg]],
                                               _ predicateMode: NSCompoundPredicate.LogicalType,
                                               _ qos: DispatchQoS.QoSClass,
                                               _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        let predicate = predicateForProperties(props, predicateMode)
        
        let propTransform: HMTransform<HMCDRequest> = {
            Observable.just($0.cloneBuilder()
                .with(predicate: predicate)
                .with(description: "Fetching \(cls) with \(props)")
                .build())
        }
        
        let allTransforms = [propTransform] + transforms
        
        return fetchAllDataFromDB(previous, cls, qos, allTransforms)
    }
    
    /// Delete all objects that have some properties.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - props: The properties to search for.
    ///   - predicateMode: A NSCompoundPredicate.LogicalType instance.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func deleteWithProperties<Prev,PO,S>(_ previous: Try<Prev>,
                                                _ cls: PO.Type,
                                                _ props: [String : [CVarArg]],
                                                _ predicateMode: NSCompoundPredicate.LogicalType,
                                                _ qos: DispatchQoS.QoSClass,
                                                _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        let predicate = predicateForProperties(props, predicateMode)
        
        let propTransform: HMTransform<HMCDRequest> = {
            Observable.just($0.cloneBuilder()
                .with(predicate: predicate)
                .with(description: "Deleting \(cls) with \(props)")
                .build())
        }
        
        let allTransforms = [propTransform] + transforms
        
        return deleteAllInMemory(previous, cls, qos, allTransforms)
    }
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Get the predicate for some text search requests.
    ///
    /// - Parameter:
    ///   - requests: A Sequence of text search requests.
    ///   - joinMode: A NSCompoundPredicate.LogicalType instance.
    /// - Returns: A NSPredicate instance.
    /// - Throws: Exception if any of the request fails.
    private func predicateForTextSearch<S>(
        _ requests: S,
        _ joinMode: NSCompoundPredicate.LogicalType) throws -> NSPredicate where
        S: Sequence, S.Element == HMCDTextSearchRequest
    {
        let predicates = try requests.map({try $0.textSearchPredicate()})
        return NSCompoundPredicate(type: joinMode, subpredicates: predicates)
    }
    
    /// Fetch some objects using text search requests.
    ///
    /// Please note that this method only takes care of basic cases as it uses
    /// AND to combine the predicates. For more sophisticated queries please
    /// consider writing a custom predicate for fetchAllDataFromDB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - requests: A Sequence of text search requests.
    ///   - predicateMode: A NSCompoundPredicate.LogicalType instance.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchWithTextSearch<Prev,PO,S>(_ previous: Try<Prev>,
                                               _ cls: PO.Type,
                                               _ requests: [HMCDTextSearchRequest],
                                               _ predicateMode: NSCompoundPredicate.LogicalType,
                                               _ qos: DispatchQoS.QoSClass,
                                               _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        do {
            let predicate = try predicateForTextSearch(requests, predicateMode)
            
            let tsTransform: HMTransform<HMCDRequest> = {
                Observable.just($0.cloneBuilder()
                    .with(predicate: predicate)
                    .build())
            }
            
            let allTransforms = [tsTransform] + transforms
            return fetchAllDataFromDB(Try.success(()), cls, qos, allTransforms)
        } catch let e {
            return Observable.just(Try.failure(e))
        }
    }
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Delete all data of some type in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - cls: A PO class type.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func deleteAllInMemory<Prev,PO,S>(_ previous: Try<Prev>,
                                             _ cls: PO.Type,
                                             _ qos: DispatchQoS.QoSClass,
                                             _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        let entityName = try? cls.CDClass.entityName()
        
        let deleteTransform: HMTransform<HMCDRequest> = {
            Observable.just($0.cloneBuilder()
                .with(poType: cls)
                .with(description: "Delete all items for \(cls)")
                .build())
        }
        
        let allTransforms = [deleteTransform] + transforms
        
        return deleteAllInMemory(previous, entityName, qos, allTransforms)
    }
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Start a paginated stream that relies on another Observable to produce
    /// pagination. Everytime the pagination Observable emits an event, we
    /// initialize a new stream and unsubscribe from old ones.
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - pageObs: An ObservableConvertibleType instance that emits paginations.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamPaginatedDBEvents<PO,O,S>(_ cls: PO.Type,
                                                _ pageObs: O,
                                                _ qos: DispatchQoS.QoSClass,
                                                _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCDPaginationProviderType,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        return pageObs.asObservable()
            .flatMapLatest({page -> Observable<Try<HMCDEvent<PO>>> in
                let pageTransform: HMTransform<HMCDRequest> = {
                    Observable.just($0.cloneBuilder()
                        .with(fetchLimit: Int(page.fetchLimit()))
                        .with(fetchOffset: Int(page.fetchOffset()))
                        .build())
                }
                
                let allTransforms = [pageTransform] + transforms
                return self.streamDBEvents(cls, qos, allTransforms)
            })
    }
    
    /// Stream events paginated by increments. The most likely uses for this
    /// method are:
    ///
    /// - A stream that gradually increases fetch limit count while keeping
    ///   fetch offset the same (e.g. a chat application).
    ///
    /// - A stream that gradually increases fetch offset while keeping fetch
    ///   limit the same (e.g. content by page).
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - pageObs: An ObservableConvertibleType instance that emits anything.
    ///   - pagination: The original HMCDPagination instance.
    ///   - qos: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamPaginatedDBEvents<PO,O,S>(_ cls: PO.Type,
                                                _ pageObs: O,
                                                _ pagination: HMCDPagination,
                                                _ qos: DispatchQoS.QoSClass,
                                                _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCursorDirection,
        S: Sequence,
        S.Element == HMTransform<HMCDRequest>
    {
        let paginationObs = pageObs.asObservable()
            .catchErrorJustReturn(.remain)
            
            // We want to minimum page number to be 1 so that it's easier to
            // produce a positive fetch limit when multiplied with this. If the
            // min is 0, we may need to do extra work to ensure the limit is
            // larger than 0.
            .scan(0, accumulator: self.currentPage)
            .distinctUntilChanged()
            .map({UInt($0)})
            .map({pagination.cloneBuilder()
                .with(fetchLimit: pagination.fetchLimitWithMultiple($0))
                .with(fetchOffset: pagination.fetchOffsetWithMultiple($0))
                .build()
            })
            .map({$0.asProtocol()})
        
        return streamPaginatedDBEvents(cls, paginationObs, qos, transforms)
    }
    
    /// Get the current page based on the cursor direction.
    ///
    /// - Parameters:
    ///   - accumulator: The previous page number.
    ///   - direction: A HMCursorDirection instance.
    /// - Returns: An Int value.
    func currentPage(_ accumulator: Int, _ direction: HMCursorDirection) -> Int {
        return Swift.max(accumulator + 1 * direction.rawValue, 1)
    }
}

// MARK: - Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                            _ cls: PO.Type,
                                            _ qos: DispatchQoS.QoSClass,
                                            _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchAllDataFromDB(previous, cls, qos, transforms)
    }
    
    public func fetchWithProperties<Prev,PO>(
        _ previous: Try<Prev>,
        _ cls: PO.Type,
        _ props: [String : [CVarArg]],
        _ predicateMode: NSCompoundPredicate.LogicalType,
        _ qos: DispatchQoS.QoSClass,
        _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchWithProperties(previous,
                                   cls,
                                   props,
                                   predicateMode,
                                   qos,
                                   transforms)
    }
    
    public func fetchWithTextSearch<Prev,PO>(_ previous: Try<Prev>,
                                             _ cls: PO.Type,
                                             _ requests: [HMCDTextSearchRequest],
                                             _ predicateMode: NSCompoundPredicate.LogicalType,
                                             _ qos: DispatchQoS.QoSClass,
                                             _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchWithTextSearch(previous,
                                   cls,
                                   requests,
                                   predicateMode,
                                   qos,
                                   transforms)
    }
}

// MARK: - Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func saveToMemory<PO>(_ previous: Try<[PO]>,
                                 _ qos: DispatchQoS.QoSClass,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return saveToMemory(previous, qos, transforms)
    }
    
    public func upsertInMemory<U>(_ previous: Try<[U]>,
                                  _ qos: DispatchQoS.QoSClass,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    {
        return upsertInMemory(previous, qos, transforms)
    }
    
    public func upsertInMemory<PO>(_ previous: Try<[PO]>,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return upsertInMemory(previous, qos, transforms)
    }
    
    public func persistToDB<Prev>(_ previous: Try<Prev>,
                                  _ qos: DispatchQoS.QoSClass,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return persistToDB(previous, qos, transforms)
    }
}

// MARK: - Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func deleteInMemory<PO>(_ previous: Try<[PO]>,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType
    {
        return deleteInMemory(previous, qos, transforms)
    }
    
    public func deleteAllInMemory<Prev>(_ previous: Try<Prev>,
                                        _ entityName: String?,
                                        _ qos: DispatchQoS.QoSClass,
                                        _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return deleteAllInMemory(previous, entityName, qos, transforms)
    }
    
    public func deleteAllInMemory<Prev,PO>(_ previous: Try<Prev>,
                                           _ cls: PO.Type,
                                           _ qos: DispatchQoS.QoSClass,
                                           _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return deleteAllInMemory(previous, cls, qos, transforms)
    }
    
    public func deleteWithProperties<Prev,PO>(_ previous: Try<Prev>,
                                              _ cls: PO.Type,
                                              _ props: [String : [CVarArg]],
                                              _ predicateMode: NSCompoundPredicate.LogicalType,
                                              _ qos: DispatchQoS.QoSClass,
                                              _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return deleteWithProperties(previous,
                                    cls,
                                    props,
                                    predicateMode,
                                    qos,
                                    transforms)
    }
}

// MARK: - Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func resetStack<Prev>(_ previous: Try<Prev>,
                                 _ qos: DispatchQoS.QoSClass,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return resetStack(previous, qos, transforms)
    }
}

// MARK: - Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func streamDBEvents<PO>(_ cls: PO.Type,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return streamDBEvents(cls, qos, transforms)
    }
    
    public func streamPaginatedDBEvents<PO,O>(_ cls: PO.Type,
                                              _ pageObs: O,
                                              _ pagination: HMCDPagination,
                                              _ qos: DispatchQoS.QoSClass,
                                              _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCursorDirection
    {
        return streamPaginatedDBEvents(cls, pageObs, pagination, qos, transforms)
    }
}
