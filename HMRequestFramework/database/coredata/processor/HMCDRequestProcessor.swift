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
    fileprivate var rqMiddlewareManager: HMMiddlewareManager<Req>?
    
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
        return rqMiddlewareManager
    }
    
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
    
    /// Perform a CoreData get request.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - cls: The Val class type.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executeFetch<Val>(_ request: Req, _ cls: Val.Type) throws
        -> Observable<Try<[Val]>>
        where Val: NSFetchRequestResult
    {
        let manager = coreDataManager()
        let cdRequest = try request.fetchRequest(Val.self)
    
        return manager.rx.fetch(cdRequest)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
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
    
    /// Perform a CoreData saveData operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executeSaveData(_ request: Req) throws -> Observable<Try<[HMCDResult]>> {
        let manager = coreDataManager()
        let insertedData = try request.insertedData()
        
        return manager.rx.save(insertedData)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        let operation = try request.operation()
        
        switch operation {
        case .delete:
            return try executeDelete(request)
            
        case .persistLocally:
            return try executePersistToFile(request)
            
        case .fetch, .saveData, .upsert:
            throw Exception("Please use typed execute for \(operation)")
        }
    }
    
    /// Perform a CoreData delete operation. This operation detects identifiable
    /// objects and treat those objects differently.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executeDelete(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let entityName = try request.entityName()
        let data = try request.deletedData()
        
        // We deal with identifiables and normal managed objects differently.
        // For identifiables, we need to fetch their counterparts in the DB
        // first before deleting.
        let identifiables = data.flatMap({$0 as? HMCDIdentifiableType})
        let nonIdentifiables = data.filter({!($0 is HMCDIdentifiableType)})
        
        return Observable
            .concat(
                manager.rx.delete(entityName, identifiables),
                manager.rx.delete(nonIdentifiables)
            )
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Perform a CoreData data persistence operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executePersistToFile(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        
        return manager.rx.persistLocally()
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
    
    /// Perform a CoreData upsert operation.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executeUpsert(_ request: Req) throws -> Observable<Try<[HMCDResult]>> {
        let manager = coreDataManager()
        let data = try request.upsertedData()
        let entityName = try request.entityName()
        
        // If the data requires versioning, we call updateVersionn.
        let versionables = data.flatMap({$0 as? HMCDVersionableType})
        let nonVersionables = data.filter({!($0 is HMCDVersionableType)})
        let updateRequests = try request.updateRequest(versionables)
        
        return Observable
            .concat(
                manager.rx.updateVersion(entityName, updateRequests),
                manager.rx.upsert(entityName, nonVersionables)
            )
            .reduce([], accumulator: +)
            .map(Try.success)
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
        public func with(manager: HMCDManager) -> Self {
            processor.manager = manager
            return self
        }
        
        /// Set the request middleware manager.
        ///
        /// - Parameter rqMiddlewareManager: A HMMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(rqMiddlewareManager: HMMiddlewareManager<Req>?) -> Self {
            processor.rqMiddlewareManager = rqMiddlewareManager
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
            .with(rqMiddlewareManager: buildable.requestMiddlewareManager())
    }
    
    public func build() -> Buildable {
        return processor
    }
}
