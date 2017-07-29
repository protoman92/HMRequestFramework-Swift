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
    
    fileprivate func coreDataManager() -> HMCDManager {
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
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req> {
        if let rqMiddlewareManager = self.rqMiddlewareManager {
            return rqMiddlewareManager
        } else {
            fatalError("Request middleware manager cannot be nil")
        }
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter cls: A HMCDType class type.
    /// - Returns: A HMCD object.
    /// - Throws: Exception if the construction fails.
    public func construct<CD>(_ cls: CD.Type) throws -> CD where CD: HMCDRepresentableType {
        return try coreDataManager().construct(cls)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter pureObj: A HMCDPureObjectType instance.
    /// - Returns: A HMCDBuildable object.
    /// - Throws: Exception if the construction fails.
    public func construct<PO>(_ pureObj: PO) throws -> PO.CDClass where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDBuildable,
        PO.CDClass.Builder.Base == PO
    {
        return try coreDataManager().construct(pureObj)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if no context is available.
    public func executeTyped<Val>(_ request: Req) throws -> Observable<Try<Val>>
        where Val: NSFetchRequestResult
    {
        let operation = try request.operation()
        
        switch operation {
        case .fetch:
            return try executeFetch(request)
            
        default:
            throw Exception("Please use normal execute for void return values")
        }
    }
    
    /// Perform a CoreData get request.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executeFetch<Val>(_ request: Req) throws -> Observable<Try<Val>>
        where Val: NSFetchRequestResult
    {
        let manager = coreDataManager()
        let cdRequest: NSFetchRequest<Val> = try request.fetchRequest()
    
        return Observable.just(cdRequest)
            .flatMap(manager.rx.fetch)
            .retry(request.retries())
            .map(Try<Val>.success)
            .catchErrorJustReturn(Try<Val>.failure)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        let operation = try request.operation()
        
        switch operation {
        case .persist:
            return try executePersist(request)
            
        case .fetch:
            throw Exception("Please use typed execute for typed return values")
        }
    }
    
    /// Perform a CoreData data persistence operation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executePersist(_ request: Req) throws -> Observable<Try<Void>> {
        let manager = coreDataManager()
        let data = try request.dataToSave()
            
        return manager.rx.saveToFile(data)
            .retry(request.retries())
            .map(Try.success)
            .catchErrorJustReturn(Try.failure)
    }
}

public extension HMCDRequestProcessor {
    public static func builder() -> Builder {
        return Builder()
    }
    
    /// Get a Builder instance and copy dependencies to the new processor.
    ///
    /// - Returns: A Builder instance.
    public func builder() -> Builder {
        return HMCDRequestProcessor.builder().with(processor: self)
    }
    
    public final class Builder {
        public typealias Req = HMCDRequestProcessor.Req
        private var processor: HMCDRequestProcessor
        
        fileprivate init() {
            processor = HMCDRequestProcessor()
        }
        
        /// Set the manager instance.
        ///
        /// - Parameter manager: A HMCDManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(manager: HMCDManager) -> Builder {
            processor.manager = manager
            return self
        }
        
        /// Set the request middleware manager.
        ///
        /// - Parameter requestMiddlewareManager: A HMMiddlewareManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(requestMiddlewareManager: HMMiddlewareManager<Req>) -> Builder {
            processor.rqMiddlewareManager = requestMiddlewareManager
            return self
        }
        
        /// Copy dependencies from another processor.
        ///
        /// - Parameter processor: A HMCDRequestProcessor instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(processor: HMCDRequestProcessor) -> Builder {
            return self
                .with(manager: processor.coreDataManager())
                .with(requestMiddlewareManager: processor.requestMiddlewareManager())
        }
        
        public func build() -> HMCDRequestProcessor {
            return processor
        }
    }
}
