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
    
    fileprivate init() {}
}

extension HMCDRequestProcessor: HMCDRequestProcessorType {
    public typealias Req = HMCDRequestType
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter cls: A HMCDType class type.
    /// - Returns: A HMCD object.
    /// - Throws: Exception if the construction fails.
    public func construct<CD>(_ cls: CD.Type) throws -> CD where CD: HMCDConvertibleType {
        if let manager = self.manager {
            return try manager.construct(cls)
        } else {
            throw Exception("CoreData manager cannot be nil")
        }
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter parsable: A HMCDParsableType instance.
    /// - Returns: A HMCDBuildable object.
    /// - Throws: Exception if the construction fails.
    public func construct<PS>(_ parsable: PS) throws -> PS.CDClass where
        PS: HMCDParsableType,
        PS.CDClass: HMCDBuildable,
        PS.CDClass.Builder.Base == PS
    {
        if let manager = self.manager {
            return try manager.construct(parsable)
        } else {
            throw Exception("CoreData manager cannot be nil")
        }
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
        if let manager = self.manager {
            let cdRequest: NSFetchRequest<Val> = try request.fetchRequest()
    
            return Observable.just(cdRequest)
                .flatMap(manager.rx.fetch)
                .retry(request.retries())
                .map(Try<Val>.success)
                .catchErrorJustReturn(Try<Val>.failure)
        } else {
            throw Exception("CoreData manager cannot be nil")
        }
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
            
        case .persistData:
            return try executePersistData(request)
            
        case .fetch:
            throw Exception("Please use typed execute for typed return values")
        }
    }
    
    /// Perform a CoreData persistence operation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executePersist(_ request: Req) throws -> Observable<Try<Void>> {
        if let manager = self.manager {
            return manager.rx.persistAll()
                .retry(request.retries())
                .map(Try.success)
                .catchErrorJustReturn(Try.failure)
        } else {
            throw Exception("CoreData manager cannot be nil")
        }
    }
    
    /// Perform a CoreData data persistence operation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if the execution fails.
    private func executePersistData(_ request: Req) throws -> Observable<Try<Void>> {
        if let manager = self.manager {
            let data = try request.dataToSave()
            
            return manager.rx.saveToFile(data)
                .retry(request.retries())
                .map(Try.success)
                .catchErrorJustReturn(Try.failure)
        } else {
            throw Exception("CoreData manager, or data cannot be nil")
        }
    }
}

public extension HMCDRequestProcessor {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
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
        
        public func build() -> HMCDRequestProcessor {
            return processor
        }
    }
}
