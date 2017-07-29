//
//  NetworkingTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 6/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import RxTest
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework

public final class NetworkingTest: XCTestCase {
    fileprivate typealias Req = HMNetworkRequestHandler.Req
    fileprivate let dummy: Try<Void> = Try.success(())
    fileprivate let timeout: TimeInterval = 100
    fileprivate var disposeBag: DisposeBag!
    fileprivate var rqMiddlewareManager: HMMiddlewareManager<Req>!
    fileprivate var handler: HMNetworkRequestHandler!
    fileprivate var processor: HMNetworkRequestProcessor!
    fileprivate var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        rqMiddlewareManager = HMMiddlewareManager<Req>.builder().build()
        
        handler = HMNetworkRequestHandler.builder()
            .with(urlSession: .shared)
            .with(requestMiddlewareManager: rqMiddlewareManager)
            .build()
        
        processor = HMNetworkRequestProcessor(handler: handler)
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    public func test_responseProcessingFailed_shouldNotThrowError() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(method: .get)
            .build()
        
        let generator: HMRequestGenerator<Void,HMNetworkRequest> = {_ in
            Observable.just(Try.success(request))
        }
        
        let processor: HMResultProcessor<Any,Any> = {_ in
            throw Exception("Error!")
        }
        
        /// When
        self.processor.process(dummy, generator, processor)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 1)
        
        let first = elements.first!
        XCTAssertTrue(first.isFailure)
    }
    
    public func test_addRequestMiddlewares_shouldAddHeaders() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(method: .get)
            .build()
        
        let generator: HMRequestGenerator<Void,HMNetworkRequest> = {_ in
            Observable.just(Try.success(request))
        }
        
        let processor: HMEQResultProcessor<Any> = HMResultProcessors.eqResultProcessor()
        let headers = ["Key1" : "Value1"]
        
        // We set this as a side effect to verify that the method was called.
        // In practice, never do this.
        var requestObject: Req? = nil
        
        let rqtf1: HMTransformMiddleware<Req> = {
            Observable.just($0.map({$0.builder().with(headers: headers).build()}))
        }
        
        let rqse1: HMSideEffectMiddleware<Req> = {
            XCTAssertTrue($0.isSuccess)
            let request = try! $0.getOrThrow()
            let rqHeaders = try! request.headers()
            XCTAssertNotNil(headers)
            XCTAssertEqual(headers, rqHeaders!)
            requestObject = request
        }

        // Need to reset properties here because these are all structs
        rqMiddlewareManager.tfMiddlewares.append(rqtf1)
        rqMiddlewareManager.seMiddlewares.append(rqse1)
        handler.rqMiddlewareManager = rqMiddlewareManager
        
        // Use a different network processor because handler is a let variable.
        let nwProcessor = HMNetworkRequestProcessor(handler: handler)
        
        /// When
        nwProcessor.process(dummy, generator, processor)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertNotNil(requestObject)
    }
}

fileprivate enum MockResource {
    case empty
}

extension MockResource: HMNetworkResourceType {
    func baseUrl() -> String {
        return "http://google.com"
    }
    
    func endPoint() -> String {
        switch self {
        case .empty:
            return ""
        }
    }
}
