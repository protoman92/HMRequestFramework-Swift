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

public struct HMDatabaseRequestProcessor {
    public let processor: HMCDRequestProcessor
    
    public init(processor: HMCDRequestProcessor) {
        self.processor = processor
    }
}

extension HMDatabaseRequestProcessor: HMCDRequestProcessorType {
    public typealias Req = HMCDRequestProcessor.Req
    
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req> {
        return processor.requestMiddlewareManager()
    }
    
    public func construct<CD>(_ cls: CD.Type) throws -> CD where CD: HMCDRepresentableType {
        return try processor.construct(cls)
    }
    
    public func construct<PO>(_ pureObj: PO) throws -> PO.CDClass where
        PO: HMCDPureObjectType,
        PO == PO.CDClass.Builder.Base,
        PO.CDClass: HMCDBuildable
    {
        return try processor.construct(pureObj)
    }
    
    public func executeTyped<Val>(_ request: Req) throws -> Observable<Try<Val>>
        where Val : NSFetchRequestResult
    {
        return try processor.executeTyped(request)
    }
    
    public func execute(_ request: Req) throws -> Observable<Try<Void>> {
        return try processor.execute(request)
    }
}
