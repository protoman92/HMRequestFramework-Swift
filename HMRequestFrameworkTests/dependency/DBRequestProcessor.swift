//
//  DBRequestProcessor.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities
@testable import HMRequestFramework

public struct DBRequestProcessor {
    public let processor: HMCDRequestProcessor
    
    public init(processor: HMCDRequestProcessor) {
        self.processor = processor
    }
}

extension DBRequestProcessor: HMCDRequestProcessorType {
    public typealias Req = HMCDRequestProcessor.Req
    
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req>? {
        return processor.requestMiddlewareManager()
    }
    
    public func executeTyped<Val>(_ request: Req) throws -> Observable<Try<[Val]>>
        where Val : NSFetchRequestResult
    {
        return try processor.executeTyped(request)
    }
    
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        return try processor.execute(request)
    }
}
