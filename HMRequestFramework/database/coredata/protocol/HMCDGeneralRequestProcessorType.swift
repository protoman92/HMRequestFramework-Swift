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
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func fetchAllDataFromDB<Prev,PO,S>(_ previous: Try<Prev>,
                                       _ cls: PO.Type,
                                       _ defaultQoS: DispatchQoS.QoSClass,
                                       _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Save some data to memory by constructing them and then saving the
    /// resulting managed objects.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - defaultQoS: The QosClass to be used for CD object construction.
    ///   - transforms: A Sequence of Request transformer.
    /// - Returns: An Observable instance.
    func saveToMemory<PO,S>(_ previous: Try<[PO]>,
                            _ defaultQoS: DispatchQoS.QoSClass,
                            _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Delete some data in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteInMemory<PO,S>(_ previous: Try<[PO]>,
                              _ defaultQoS: DispatchQoS.QoSClass,
                              _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Delete all data of some type in memory.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - cls: A PO class type.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func deleteAllInMemory<Prev,PO,S>(_ previous: Try<Prev>,
                                      _ cls: PO.Type,
                                      _ defaultQoS: DispatchQoS.QoSClass,
                                      _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Reset the CoreData stack and wipe DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func resetStack<Prev,S>(_ previous: Try<Prev>,
                            _ defaultQoS: DispatchQoS.QoSClass,
                            _ transforms: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Perform an upsert operation with some upsertable data.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<U,S>(_ previous: Try<[U]>,
                             _ defaultQoS: DispatchQoS.QoSClass,
                             _ transforms: S)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Perform an upsert operation with some pure objects by constructing
    /// managed objects and then upserting them afterwards.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - defaultQoS: The QoSClass to be used for CD object construction.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func upsertInMemory<PO,S>(_ previous: Try<[PO]>,
                              _ defaultQoS: DispatchQoS.QoSClass,
                              _ transform: S)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Persist all data to DB.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transform: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func persistToDB<Prev,S>(_ previous: Try<Prev>,
                             _ defaultQoS: DispatchQoS.QoSClass,
                             _ transform: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransform<HMCDRequest>
    
    /// Stream DB changes for some pure object type.
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    func streamDBEvents<S,PO>(_ cls: PO.Type,
                              _ defaultQoS: DispatchQoS.QoSClass,
                              _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
}

public extension HMCDGeneralRequestProcessorType {
    
    /// Get the predicate from some object properties for a fetch/delete
    /// operation.
    ///
    /// - Parameter properties: A Dictionary of properties.
    /// - Returns: A NSPredicate instance.
    private func predicateForProperties(_ properties: [String : [CVarArg]])
        -> NSPredicate
    {
        return NSCompoundPredicate(andPredicateWithSubpredicates:
            properties.map({NSPredicate(format: "%K in %@", $0.0, $0.1)})
        )
    }
    
    /// Fetch all data that have some properties. These properties will be
    /// mapped into a series of predicates and joined together with AND.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchWithProperties<PO,S>(_ previous: Try<[String : [CVarArg]]>,
                                          _ cls: PO.Type,
                                          _ defaultQoS: DispatchQoS.QoSClass,
                                          _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    {
        do {
            let properties = try previous.getOrThrow()
            let predicate = predicateForProperties(properties)
            
            let propTransform: HMTransform<HMCDRequest> = {
                Observable.just($0.cloneBuilder()
                    .with(predicate: predicate)
                    .with(description: "Fetching \(cls) with \(properties)")
                    .build())
            }
            
            let allTransforms = [propTransform] + transforms
            
            return fetchAllDataFromDB(Try.success(()), cls, defaultQoS, allTransforms)
                .doOnNext(Preconditions.checkNotRunningOnMainThread)
        } catch let e {
            return Observable.just(Try.failure(e))
        }
    }
    
    /// Delete all objects that have some properties.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PO class type.
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func deleteWithProperties<PO,S>(_ previous: Try<[String : [CVarArg]]>,
                                           _ cls: PO.Type,
                                           _ defaultQoS: DispatchQoS.QoSClass,
                                           _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
    {
        do {
            let properties = try previous.getOrThrow()
            let predicate = predicateForProperties(properties)
            
            let propTransform: HMTransform<HMCDRequest> = {
                Observable.just($0.cloneBuilder()
                    .with(predicate: predicate)
                    .with(description: "Deleting \(cls) with \(properties)")
                    .build())
            }
            
            let allTransforms = [propTransform] + transforms
            
            return deleteAllInMemory(previous, cls, defaultQoS, allTransforms)
                .doOnNext(Preconditions.checkNotRunningOnMainThread)
        } catch let e {
            return Observable.just(Try.failure(e))
        }
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
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamPaginatedDBEvents<PO,O,S>(_ cls: PO.Type,
                                                _ pageObs: O,
                                                _ defaultQoS: DispatchQoS.QoSClass,
                                                _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCDPaginationProviderType,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
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
                return self.streamDBEvents(cls, defaultQoS, allTransforms)
            })
            .doOnNext(Preconditions.checkNotRunningOnMainThread)
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
    ///   - defaultQoS: A QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamPaginatedDBEvents<PO,O,S>(_ cls: PO.Type,
                                                _ pageObs: O,
                                                _ pagination: HMCDPagination,
                                                _ defaultQoS: DispatchQoS.QoSClass,
                                                _ transforms: S)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCursorDirection,
        S: Sequence,
        S.Iterator.Element == HMTransform<HMCDRequest>
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
        
        return streamPaginatedDBEvents(cls, paginationObs, defaultQoS, transforms)
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

/// Convenience method for varargs.
public extension HMCDGeneralRequestProcessorType {
    public func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                            _ cls: PO.Type,
                                            _ defaultQoS: DispatchQoS.QoSClass,
                                            _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchAllDataFromDB(previous, cls, defaultQoS, transforms)
    }
    
    public func fetchWithProperties<PO>(_ previous: Try<[String : [CVarArg]]>,
                                        _ cls: PO.Type,
                                        _ defaultQoS: DispatchQoS.QoSClass,
                                        _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return fetchWithProperties(previous, cls, defaultQoS, transforms)
    }
    
    public func saveToMemory<PO>(_ previous: Try<[PO]>,
                                 _ defaultQoS: DispatchQoS.QoSClass,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return saveToMemory(previous, defaultQoS, transforms)
    }
    
    public func deleteInMemory<PO>(_ previous: Try<[PO]>,
                                   _ defaultQoS: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType
    {
        return deleteInMemory(previous, defaultQoS, transforms)
    }
    
    public func deleteAllInMemory<Prev,PO>(_ previous: Try<Prev>,
                                           _ cls: PO.Type,
                                           _ defaultQoS: DispatchQoS.QoSClass,
                                           _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return deleteAllInMemory(previous, cls, defaultQoS, transforms)
    }
    
    public func deleteWithProperties<PO>(_ previous: Try<[String : [CVarArg]]>,
                                         _ cls: PO.Type,
                                         _ defaultQoS: DispatchQoS.QoSClass,
                                         _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return deleteWithProperties(previous, cls, defaultQoS, transforms)
    }
    
    public func resetStack<Prev>(_ previous: Try<Prev>,
                                 _ defaultQoS: DispatchQoS.QoSClass,
                                 _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return resetStack(previous, defaultQoS, transforms)
    }
    
    public func upsertInMemory<U>(_ previous: Try<[U]>,
                                  _ defaultQoS: DispatchQoS.QoSClass,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    {
        return upsertInMemory(previous, defaultQoS, transforms)
    }
    
    public func upsertInMemory<PO>(_ previous: Try<[PO]>,
                                   _ defaultQoS: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return upsertInMemory(previous, defaultQoS, transforms)
    }
    
    public func persistToDB<Prev>(_ previous: Try<Prev>,
                                  _ defaultQoS: DispatchQoS.QoSClass,
                                  _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<Void>>
    {
        return persistToDB(previous, defaultQoS, transforms)
    }
    
    public func streamDBEvents<PO>(_ cls: PO.Type,
                                   _ defaultQoS: DispatchQoS.QoSClass,
                                   _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return streamDBEvents(cls, defaultQoS, transforms)
    }
    
    public func streamPaginatedDBEvents<PO,O>(_ cls: PO.Type,
                                              _ pageObs: O,
                                              _ pagination: HMCDPagination,
                                              _ defaultQoS: DispatchQoS.QoSClass,
                                              _ transforms: HMTransform<HMCDRequest>...)
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        O: ObservableConvertibleType,
        O.E == HMCursorDirection
    {
        return streamPaginatedDBEvents(cls, pageObs, pagination, defaultQoS, transforms)
    }
}
