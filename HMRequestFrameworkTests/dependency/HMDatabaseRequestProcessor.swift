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
    public typealias Req = HMCDRequestType
    
    public func construct<CD>(_ cls: CD.Type) throws -> CD where CD: HMCDType {
        return try processor.construct(cls)
    }
    
    public func construct<PS>(_ parsable: PS) throws -> PS.CDClass where
        PS: HMCDParsableType,
        PS == PS.CDClass.Builder.Base,
        PS.CDClass: HMCDBuildable
    {
        return try processor.construct(parsable)
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
