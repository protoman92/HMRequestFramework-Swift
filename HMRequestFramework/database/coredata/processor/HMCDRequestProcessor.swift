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
    fileprivate var rqmManager: HMMiddlewareManager<Req>?
    
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
    /// - Returns: A HMMiddlewareManager instance.
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req>? {
        return rqmManager
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
            return try executeDelete(request)
            
        case .deleteBatch:
            return try executeDeleteWithRequest(request)
            
        case .persistLocally:
            return try executePersistToFile(request)
            
        case .resetStack:
            return try executeResetStack(request)
            
        case .fetch, .saveData, .upsert:
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
        -> Observable<Try<[Val]>>
        where Val: NSFetchRequestResult
    {
        let manager = coreDataManager()
        let cdRequest = try request.fetchRequest(Val.self)
        let context = manager.disposableObjectContext()
    
        return manager.rx.fetch(context, cdRequest)
            .retry(request.retries())
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
        
        return manager.rx.saveConvertibles(context, insertedData)
            .retry(request.retries())
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
        
        return manager.rx.persistLocally()
            .retry(request.retries())
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
        
        return manager.rx.resetStack()
            .retry(request.retries())
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
        
        // If the data requires versioning, we call updateVersionn.
        let versionables = data.flatMap({$0 as? HMCDVersionableType})
        let nonVersionables = data.filter({!($0 is HMCDVersionableType)})
        let updateRequests = try request.updateRequest(versionables)
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        
        return Observable
            .concat(
                manager.rx.updateVersion(context1, entityName, updateRequests),
                manager.rx.upsert(context2, entityName, nonVersionables)
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
    fileprivate func executeDelete(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let context = manager.disposableObjectContext()
        let entityName = try request.entityName()
        let data = try request.deletedData()
        
        // Since both CoreData and PureObject can implement HMCDObjectConvertibleType,
        // we can convert them all to NSManagedObject and delete them based on
        // whether they are identifiable or not.
        //
        // We delete NSManagedObject using their ObjectID. If not, we construct
        // the managed objects using a disposable context, and see if any of
        // these objects is identifiable.
        let aliases = data.flatMap({$0 as? NSManagedObject})
        
        let nonAliases = data.filter({!($0 is NSManagedObject)})
            .flatMap({try? $0.asManagedObject(context)})
        
        let objects = [aliases, nonAliases].flatMap({$0})
        
        // We deal with identifiables and normal managed objects differently.
        // For identifiables, we need to fetch their counterparts in the DB
        // first before deleting.
        let ids = objects.flatMap({$0 as? HMCDIdentifiableType})
        let nonIds = objects.filter({!($0 is HMCDIdentifiableType)})
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        
        return Observable
            .concat(
                manager.rx.deleteIdentifiables(context1, entityName, ids),
                manager.rx.delete(context2, nonIds)
            )
            .reduce((), accumulator: {_ in ()})
            .retry(request.retries())
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
    fileprivate func executeDeleteWithRequest(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        
        if manager.isMainStoreTypeSQLite() {
            return try executeBatchDelete(request)
        } else {
            return try executeFetchAndDelete(request)
        }
    }
    
    /// Perform a batch delete operation. This only works for SQLite stores.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeBatchDelete(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let deleteRequest = try request.untypedFetchRequest()
        let context = manager.disposableObjectContext()
        
        return manager.rx.delete(context, deleteRequest)
            .map(toVoid)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Fetch some data from DB then delete them. This should only be used
    /// when we want to batch-delete data but the store type is not SQLite.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    fileprivate func executeFetchAndDelete(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let fetchContext = manager.disposableObjectContext()
        let deleteContext = manager.disposableObjectContext()
        let fetchRequest = try request.fetchRequest(NSManagedObject.self)
        
        return manager.rx.fetch(fetchContext, fetchRequest)
            .flatMap({manager.rx.delete(deleteContext, $0)})
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    public func fetchAllRequest<PO>(_ cls: PO.Type) -> Req where PO: HMCDPureObjectType {
        return Req.builder()
            .with(operation: .fetch)
            .with(poType: cls)
            .with(predicate: NSPredicate(value: true))
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - cls: The PureObject class type.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func fetchAllDataFromDB<Prev,PO,S>(_ previous: Try<Prev>,
                                              _ cls: PO.Type,
                                              _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<Req>
    {
        let request = fetchAllRequest(cls)
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return process(previous, generator, cls)
    }
}

public extension HMCDRequestProcessor {
    public func saveToMemoryRequest<CD,S>(_ data: S) -> Req where
        CD: HMCDObjectType,
        CD: HMCDObjectConvertibleType,
        S: Sequence,
        S.Iterator.Element == CD
    {
        return Req.builder()
            .with(cdType: CD.self)
            .with(operation: .saveData)
            .with(insertedData: data)
            .with(requestDescription: "Save \(CD.self) to memory")
            .shouldApplyMiddlewares()
            .build()
    }
        
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func saveToMemory<PO,S>(_ previous: Try<[PO]>, _ transforms: S)
        -> Observable<Try<Void>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectConvertibleType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<Req>
    {
        let cdManager = coreDataManager()
        let context = cdManager.disposableObjectContext()
        
        let generator: HMRequestGenerator<[PO],Req> = HMRequestGenerators.forceGn({
            cdManager.rx.construct(context, $0)
                .map(self.saveToMemoryRequest)
                .flatMap({HMTransformers.applyTransformers($0, transforms)})
        })
        
        return processResult(previous, generator).map({$0.map(toVoid)})
    }
}

public extension HMCDRequestProcessor {
    public func resetStackRequest() -> Req {
        return Req.builder()
            .with(operation: .resetStack)
            .with(requestDescription: "Reset CoreData stack")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous operation.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func resetStack<Prev,S>(_ previous: Try<Prev>, _ transforms: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransformer<Req>
    {
        let request = resetStackRequest()
        let generator = HMRequestGenerators.forceGn(request, Prev.self)
        return processVoid(previous, generator)
    }
}

public extension HMCDRequestProcessor {
    public func upsertRequest<U,S>(_ data: S) -> Req where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == U
    {
        return Req.builder()
            .with(cdType: U.self)
            .with(operation: .upsert)
            .with(upsertedData: data.map({$0 as HMCDUpsertableType}))
            .with(vcStrategy: .overwrite)
            .with(requestDescription: "Upsert \(U.self) in memory")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func upsertInMemory<U,S>(_ previous: Try<[U]>, _ transforms: S)
        -> Observable<Try<[HMCDResult]>> where
        U: HMCDObjectType,
        U: HMCDUpsertableType,
        S: Sequence,
        S.Iterator.Element == HMTransformer<Req>
    {
        let generator: HMRequestGenerator<[U],Req> = HMRequestGenerators.forceGn({
            let request = self.upsertRequest($0)
            return HMTransformers.applyTransformers(request, transforms)
        })
        
        return processResult(previous, generator)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func upsertInMemory<PO,S>(_ previous: Try<[PO]>, _ transforms: S)
        -> Observable<Try<[HMCDResult]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDUpsertableType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<Req>
    {
        let cdManager = coreDataManager()
        let context = cdManager.disposableObjectContext()
        
        return Observable.just(previous)
            .map({try $0.getOrThrow()})
            .flatMap({cdManager.rx.construct(context, $0)})
            .map(Try.success)
            .flatMap({self.upsertInMemory($0, transforms)})
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    public func persistToDBRequest() -> Req {
        return Req.builder()
            .with(operation: .persistLocally)
            .with(requestDescription: "Persist all data to DB")
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameters:
    ///   - previous: The result of the previous request.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func persistToDB<Prev,S>(_ previous: Try<Prev>, _ transforms: S)
        -> Observable<Try<Void>> where
        S: Sequence, S.Iterator.Element == HMTransformer<Req>
    {
        let request = persistToDBRequest()
        let generator = HMRequestGenerators.forceGn(request, Prev.self, transforms)
        return processVoid(previous, generator)
    }
}

public extension HMCDRequestProcessor {
    
    /// Get the basic stream request. For more sophisticated requests, please
    /// use transformers on the accompanying method (as defined below).
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: A Req instance.
    public func streamDBChangesRequest<PO>(_ cls: PO.Type) -> Req where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return Req.builder()
            .with(poType: cls)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .shouldApplyMiddlewares()
            .build()
    }
    
    /// Stream DB changes
    ///
    /// - Parameters:
    ///   - cls: The PO class type.
    ///   - transforms: A Sequence of Request transformers.
    /// - Returns: An Observable instance.
    public func streamDBChanges<S,PO>(_ cls: PO.Type, _ transforms: S)
        -> Observable<Try<[PO]>> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == HMTransformer<HMCDRequest>
    {
        let manager = coreDataManager()
        let request = streamDBChangesRequest(cls)
        
        do {
            let wrapper = try manager.getFRCWrapperForRequest(request)
            
            return Observable<Void>
                .create({
                    do {
                        // Start only when this Observable is subscribed to.
                        try wrapper.rx.startStream()
                        $0.onNext(())
                        $0.onCompleted()
                    } catch let e {
                        $0.onError(e)
                    }
                    
                    return Disposables.create()
                })
                .flatMap({wrapper.rx.stream(cls)})
                .map(Try.success)
                .catchErrorJustReturn(Try.failure)
        } catch let e {
            return Observable.just(Try.failure(e))
        }
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
        public func with(manager: HMCDManager) -> Self {
            processor.manager = manager
            return self
        }
        
        /// Set the request middleware manager.
        ///
        /// - Parameter rqmManager: A HMMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(rqmManager: HMMiddlewareManager<Req>?) -> Self {
            processor.rqmManager = rqmManager
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
    public func with(buildable: Buildable) -> Self {
        return self
            .with(manager: buildable.coreDataManager())
            .with(rqmManager: buildable.requestMiddlewareManager())
    }
    
    
    public func build() -> Buildable {
        return processor
    }
}
