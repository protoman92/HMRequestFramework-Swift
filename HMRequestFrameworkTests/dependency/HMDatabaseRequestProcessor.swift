//
//  HMDatabaseRequestProcessor.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities
@testable import HMRequestFramework

/// This class is used to hide specific database implementation. It decorates
/// over a HMRequestHandler instance to perform database requests.
///
/// The default database used here is CoreData. If we were to change the database
/// to something else, it would not leak to the upper layers.
///
/// Due to design limitations, this type shall not implement HMRequestProcessorType.
public struct HMDatabaseRequestProcessor {
    public let processor: HMCDRequestProcessor
    
    public init(processor: HMCDRequestProcessor) {
        self.processor = processor
    }
}

extension HMDatabaseRequestProcessor: HMCDRequestProcessorType {
    public typealias Req = HMCDRequestType
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if processor fails to perform request.
    public func executeTyped<Val>(_ request: Req) throws -> Observable<Try<Val>>
        where Val : NSFetchRequestResult
    {
        return try processor.executeTyped(request)
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter request: A HMCoreDataRequestType instance.
    /// - Returns: An Observable instance.
    /// - Throws: Exception if processor fails to perform request.
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        return try processor.execute(request)
    }
}
