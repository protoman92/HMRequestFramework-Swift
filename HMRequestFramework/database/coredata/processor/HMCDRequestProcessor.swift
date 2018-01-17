//
//  HMCDRequestProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// CoreData request processor class. We skip the handler due to CoreData
/// design limitations. This way, casting is done at the database level.
public struct HMCDRequestProcessor {
    fileprivate var manager: HMCDManager?
    fileprivate var rqmManager: HMFilterMiddlewareManager<Req>?
    fileprivate var emManager: HMGlobalMiddlewareManager<HMErrorHolder>?
    
    fileprivate init() {}
    
    public func coreDataManager() -> HMCDManager {
        if let manager = self.manager {
            return manager
        } else {
            fatalError("CoreData manager cannot be nil")
        }
    }
}

extension HMCDRequestProcessor: HMCDRequestProcessorType {
    public typealias Req = HMCDRequest
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMFilterMiddlewareManager instance.
    public func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>? {
        return rqmManager
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMFilterMiddlewareManager instance.
    public func errorMiddlewareManager() -> HMFilterMiddlewareManager<HMErrorHolder>? {
        return emManager
    }
}

public extension HMCDRequestProcessor {
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if no context is available.
    public func executeTyped<Val>(_ request: Req) throws -> Observable<Try<[Val]>>
        where Val: NSFetchRequestResult
    {
        let operation = try request.operation()
        
        switch operation {
        case .fetch:
            return try executeFetch(request, Val.self)
            
        default:
            throw Exception("Please use normal execute for \(operation)")
        }
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        let operation = try request.operation()
        
        switch operation {
        case .deleteData:
            return try executeDeleteData(request)
            
        case .deleteBatch:
            return try executeDeleteWithRequest(request)
            
        case .persistLocally:
            return try executePersistToFile(request)
            
        case .resetStack:
            return try executeResetStack(request)
            
        case .fetch, .saveData, .upsert, .stream:
            throw Exception("Please use typed execute for \(operation)")
        }
    }
    
    /// Overwrite this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the operation fails.
    public func executeTyped(_ request: Req) throws -> Observable<Try<[HMCDResult]>> {
        let operation = try request.operation()
        
        switch operation {
        case .saveData:
            return try executeSaveData(request)
            
        case .upsert:
            return try executeUpsert(request)
            
        default:
            throw Exception("Please use normal execute for \(operation)")
        }
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData get request.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - cls: The Val class type.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeFetch<Val>(_ request: Req, _ cls: Val.Type) throws
        -> Observable<Try<[Val]>> where Val: NSFetchRequestResult
    {
        let manager = coreDataManager()
        let cdRequest = try request.fetchRequest(Val.self)
        let context = manager.disposableObjectContext()
        let opMode = request.operationMode()
        let retries = request.retries()
        let delay = request.retryDelay()
    
        return manager.rx.fetch(context, cdRequest, opMode)
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData saveData operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeSaveData(_ request: Req) throws -> Observable<Try<[HMCDResult]>> {
        let manager = coreDataManager()
        let insertedData = try request.insertedData()
        let context = manager.disposableObjectContext()
        let opMode = request.operationMode()
        let retries = request.retries()
        let delay = request.retryDelay()
        
        return manager.rx.saveConvertibles(context, insertedData, opMode)
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData data persistence operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executePersistToFile(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let opMode = request.operationMode()
        let retries = request.retries()
        let delay = request.retryDelay()
        
        return manager.rx.persistLocally(opMode)
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData stack reset operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeResetStack(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let opMode = request.operationMode()
        let retries = request.retries()
        let delay = request.retryDelay()
        
        return manager.rx.resetStack(opMode)
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData upsert operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeUpsert(_ request: Req) throws -> Observable<Try<[HMCDResult]>> {
        let manager = coreDataManager()
        let data = try request.upsertedData()
        let entityName = try request.entityName()
        let opMode = request.operationMode()
        
        // If the data requires versioning, we call updateVersionn.
        let versionables = data.flatMap({$0 as? HMCDVersionableType})
        let nonVersionables = data.filter({!($0 is HMCDVersionableType)})
        let vRequests = try request.updateRequest(versionables)
        let versionContext = manager.disposableObjectContext()
        let upsertContext = manager.disposableObjectContext()
        
        return Observable
            .concat(
                manager.rx.updateVersion(versionContext, entityName, vRequests, opMode),
                manager.rx.upsert(upsertContext, entityName, nonVersionables, opMode)
            )
            .reduce([], accumulator: +)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// Perform a CoreData delete operation. This operation detects identifiable
    /// objects and treat those objects differently.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeDeleteData(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let entityName = try request.entityName()
        let retries = request.retries()
        let delay = request.retryDelay()
        let opMode = request.operationMode()
        
        // Putting the context outside the create block allows it to be retained
        // strongly, preventing inner managed objects from being ARC off.
        let context = manager.disposableObjectContext()
        
        // We need to use Observable.create to keep a reference to the context
        // with which NSManagedObjects are constructed. Otherwise, those objects
        // may become fault as the context is ARC off.
        return Observable<[NSManagedObject]>
            .create({
                do {
                    let data = try request.deletedData()
                    
                    // Since both CoreData and PureObject can be convertible,
                    // we can convert them all to NSManagedObject and delete them
                    // based on whether they are identifiable or not.
                    //
                    // We delete NSManagedObject using their ObjectID. If not, we
                    // construct the managed objects using a disposable context,
                    // and see if any of these objects is identifiable.
                    let aliases = data.flatMap({$0 as? NSManagedObject})
                    
                    let nonAliases = data.filter({!($0 is NSManagedObject)})
                        .flatMap({try? $0.asManagedObject(context)})
                    
                    $0.onNext([aliases, nonAliases].flatMap({$0}))
                    $0.onCompleted()
                } catch let e {
                    $0.onError(e)
                }
                
                return Disposables.create()
            })
            .flatMap({objects -> Observable<Void> in

                // We deal with identifiables and normal objects differently.
                // For identifiables, we need to fetch their counterparts in the
                // DB first before deleting.
                let ids = objects.flatMap({$0 as? HMCDIdentifiableType})
                let nonIds = objects.filter({!($0 is HMCDIdentifiableType)})
                let context1 = manager.disposableObjectContext()
                let context2 = manager.disposableObjectContext()
                
                return Observable.concat(
                    manager.rx.deleteIdentifiables(context1, entityName, ids, opMode),
                    manager.rx.delete(context2, nonIds, opMode)
                )
            })
            .reduce((), accumulator: {_, _ in ()})
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    
    /// We need this check because batch delete does not work for InMemory store.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeDeleteWithRequest(_ request: Req) throws
        -> Observable<Try<Void>>
    {
//        let manager = coreDataManager()
        
//        if manager.areAllStoresSQLite() {
//            return try executeBatchDelete(request)
//        } else {
        return try executeFetchAndDelete(request)
//        }
    }
    
    /// Perform a batch delete operation. This only works for SQLite stores.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeBatchDelete(_ request: Req) throws
        -> Observable<Try<Void>>
    {
        let manager = coreDataManager()
        let deleteRequest = try request.untypedFetchRequest()
        let context = manager.disposableObjectContext()
        let opMode = request.operationMode()
        let retries = request.retries()
        let delay = request.retryDelay()
        
        return manager.rx.delete(context, deleteRequest, opMode)
            .map(toVoid)
            .delayRetry(retries: retries, delay: delay)
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Fetch some data from DB then delete them. This should only be used
    /// when we want to batch-delete data but the store type is not SQLite.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeFetchAndDelete(_ request: Req) throws
        -> Observable<Try<Void>>
    {
        let manager = coreDataManager()
        let context = manager.disposableObjectContext()
        let opMode = request.operationMode()
        let fetchRequest = try request.fetchRequest(NSManagedObject.self)
        
        // We can reuse the context with which we performed the fetch for the
        // delete as well - this way, the NSManagedObject refetch will be very
        // fast. At the same time, this helps keep this context around so that
        // the inner managed objects are not ARC off.
        return manager.rx.fetch(context, fetchRequest, opMode)
            .flatMap({manager.rx.delete(context, $0, opMode)})
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    private func fetchAllRequest() -> Req {
        return Req.builder()
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .shouldApplyMiddlewares()
            .build()
    }
    
    public func fetchAllRequest(_ entityName: String?) -> Req {
        return fetchAllRequest().cloneBuilder()
            .with(entityName: entityName)
            .with(description: "Fetch all data for \(entityName ?? "")")
            .build()
    }
    
    public func fetchAllRequest<PO>(_ cls: PO.Type) -> Req where PO: HMCDPureObjectType {
        return fetchAllRequest().cloneBuilder()
            .with(poType: cls)
            .with(description: "Fetch all data for \(cls)")
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PureObject class type.
    ///   - qos: The QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchAllDataFromDB<Prev,PO>(_ previous: Try<Prev>,
                                            _ cls: PO.Type,
                                            _ qos: DispatchQoS.QoSClass,
                                            _ transforms: [HMTransform<Req>])
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: NSManagedObject,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        let request = fetchAllRequest(cls)
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return process(previous, generator, cls, qos)
    }
}

public extension HMCDRequestProcessor {
    public func saveToMemoryRequest<CD,S>(_ data: S) -> Req where
        CD: HMCDObjectType,
        CD: HMCDObjectConvertibleType,
        S: Sequence,
        S.Element == CD
    {
        return Req.builder()
            .with(cdType: CD.self)
            .with(operation: .saveData)
            .with(insertedData: data)
            .with(description: "Save \(CD.self) to memory")
            .shouldApplyMiddlewares()
            .build()
    }
        
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - qos: A QoSClass instance.
    ///   - qos: The QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func saveToMemory<PO>(_ previous: Try<[PO]>,
                                 _ qos: DispatchQoS.QoSClass,
                                 _ transforms: [HMTransform<Req>])
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        let manager = coreDataManager()
        let context = manager.disposableObjectContext()
        
        let generator: HMRequestGenerator<[PO],Req> = HMRequestGenerators.forceGn({
            manager.rx.construct(context, $0)
                .subscribeOnConcurrent(qos: qos)
                .map(self.saveToMemoryRequest)
                .flatMap({HMTransforms.applyTransformers($0, transforms)})
        })
        
        return processResult(previous, generator, qos)
    }
}

public extension HMCDRequestProcessor {
    public func deleteDataRequest<PO,S>(_ data: S) -> Req where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType,
        S: Sequence,
        S.Element == PO
    {
        return Req.builder()
            .with(operation: .deleteData)
            .with(poType: PO.self)
            .with(deletedData: data)
            .with(description: "Delete data \(data) in memory")
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func deleteInMemory<PO>(_ previous: Try<[PO]>,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: [HMTransform<Req>])
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO: HMCDObjectConvertibleType
    {
        let generator: HMRequestGenerator<[PO],Req> = HMRequestGenerators.forceGn({
            let request = self.deleteDataRequest($0)
            return HMTransforms.applyTransformers(request, transforms)
        })
        
        return processVoid(previous, generator, qos)
    }
}

public extension HMCDRequestProcessor {
    public func deleteAllRequest(_ entityName: String?) -> Req {
        return fetchAllRequest(entityName)
            .cloneBuilder()
            .with(operation: .deleteBatch)
            .with(description: "Delete all data for \(entityName ?? "")")
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - entityName: A String value denoting the entity name.
    ///   - qos: The QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func deleteAllInMemory<Prev>(_ previous: Try<Prev>,
                                        _ entityName: String?,
                                        _ qos: DispatchQoS.QoSClass,
                                        _ transforms: [HMTransform<Req>])
        -> Observable<Try<Void>>
    {
        let request = deleteAllRequest(entityName)
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return processVoid(previous, generator, qos)
    }
}

public extension HMCDRequestProcessor {
    public func resetStackRequest() -> Req {
        return Req.builder()
            .with(operation: .resetStack)
            .with(description: "Reset CoreData stack")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func resetStack<Prev>(_ previous: Try<Prev>,
                                 _ qos: DispatchQoS.QoSClass,
                                 _ transforms: [HMTransform<Req>])
        -> Observable<Try<Void>>
    {
        let request = resetStackRequest()
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return processVoid(previous, generator, qos)
    }
}

public extension HMCDRequestProcessor {
    public func upsertRequest<U,S>(_ data: S) -> Req where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Element == U
    {
        return Req.builder()
            .with(cdType: U.self)
            .with(operation: .upsert)
            .with(upsertedData: data.map({$0 as HMCDUpsertableType}))
            .with(vcStrategy: .overwrite)
            .with(description: "Upsert \(U.self) in memory")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    public func upsertInMemory<U>(_ previous: Try<[U]>,
                                  _ qos: DispatchQoS.QoSClass,
                                  _ transforms: [HMTransform<Req>])
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType, U: HMCDUpsertableType
    {
        let generator: HMRequestGenerator<[U],Req> = HMRequestGenerators.forceGn({
            let request = self.upsertRequest($0)
            return HMTransforms.applyTransformers(request, transforms)
        })
        
        return processResult(previous, generator, qos)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - qos: A QoSClass instance.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func upsertInMemory<PO>(_ previous: Try<[PO]>,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: [HMTransform<Req>])
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        let cdManager = coreDataManager()
        let context = cdManager.disposableObjectContext()
        
        return Observable.just(previous)
            .map({try $0.getOrThrow()})
            .flatMap({cdManager.rx.construct(context, $0)
                .subscribeOnConcurrent(qos: qos)
            })
            .map(Try.success)
            .flatMap({self.upsertInMemory($0, qos, transforms)})
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    public func persistToDBRequest() -> Req {
        return Req.builder()
            .with(operation: .persistLocally)
            .with(description: "Persist all data to DB")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - qos: The QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func persistToDB<Prev>(_ previous: Try<Prev>,
                                  _ qos: DispatchQoS.QoSClass,
                                  _ transforms: [HMTransform<Req>])
        -> Observable<Try<Void>>
    {
        let request = persistToDBRequest()
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return processVoid(previous, generator, qos)
    }
}

public extension HMCDRequestProcessor {
    
    /// Get the basic stream request. For more sophisticated requests, please
    /// use transformers on the accompanying method (as defined below).
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: A Req instance.
    public func streamDBEventsRequest<PO>(_ cls: PO.Type) -> Req where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return Req.builder()
            .with(poType: cls)
            .with(operation: .stream)
            .with(predicate: NSPredicate(value: true))
            .with(description: "Stream DB events for \(cls)")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Stream DB changes
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - qos: The QoSClass instance to perform work on.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamDBEvents<PO>(_ cls: PO.Type,
                                   _ qos: DispatchQoS.QoSClass,
                                   _ transforms: [HMTransform<Req>])
        -> Observable<Try<HMCDEvent<PO>>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        let manager = coreDataManager()
        let request = streamDBEventsRequest(cls)

        return HMTransforms
            .applyTransformers(request, transforms)
            .subscribeOnConcurrent(qos: qos)
            .flatMap({manager.rx.startDBStream($0, cls, qos)
                .map(Try.success)
                .catchErrorJustReturn(Try.failure)
            })
            .catchErrorJustReturn(Try.failure)
    }
}

extension HMCDRequestProcessor: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        public typealias Req = HMCDRequestProcessor.Req
        fileprivate var processor: Buildable
        
        fileprivate init() {
            processor = Buildable()
        }
        
        /// Set the manager instance.
        ///
        /// - Parameter manager: A HMCDManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(manager: HMCDManager?) -> Self {
            processor.manager = manager
            return self
        }
        
        /// Set the request middleware manager.
        ///
        /// - Parameter rqmManager: A HMFilterMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(rqmManager: HMFilterMiddlewareManager<Req>?) -> Self {
            processor.rqmManager = rqmManager
            return self
        }
        
        /// Set the error middleware manager.
        ///
        /// - Parameter emManager: A HMGlobalMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(emManager: HMGlobalMiddlewareManager<HMErrorHolder>?) -> Self {
            processor.emManager = emManager
            return self
        }
    }
}

extension HMCDRequestProcessor.Builder: HMBuilderType {
    public typealias Buildable = HMCDRequestProcessor
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(manager: buildable.manager)
                .with(rqmManager: buildable.rqmManager)
                .with(emManager: buildable.emManager)
        } else {
            return self
        }
    }
    
    
    public func build() -> Buildable {
        return processor
    }
}
