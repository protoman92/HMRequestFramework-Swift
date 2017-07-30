//
//  MiddlewareTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import RxTest
import SwiftUtilities
import XCTest
@testable import HMRequestFramework

public final class MiddlewareTest: XCTestCase {
    fileprivate let timeout: TimeInterval = 1000
    fileprivate var manager: HMMiddlewareManager<Int>!
    fileprivate var scheduler: TestScheduler!
    fileprivate var disposeBag: DisposeBag!
    
    override public func setUp() {
        super.setUp()
        manager = HMMiddlewareManager<Int>.builder().build()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    public func test_applyValidTransformMiddlewares_shouldWork() {
        /// Setup
        let times = 1000
        
        let times2: HMTransformMiddleware<Int> = {
            Observable.just($0 * 2)
        }
        
        let times3: HMTransformMiddleware<Int> = {
            Observable.just($0 * 3)
        }
        
        let times4: HMTransformMiddleware<Int> = {
            Observable.just($0 * 4)
        }

        let middlewares = [times2, times3, times4]
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Any.self)
        
        /// When
        Observable.range(start: 0, count: times)
            .flatMap({i in self.manager
                .applyTransformMiddlewares(i, middlewares)
                .doOnNext({XCTAssertEqual($0, i * 2 * 3 * 4)})
            })
            .cast(to: Any.self)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, times)
    }
    
    public func test_applyEmptyTransformMiddlewares_shouldReturnOriginal() {
        /// Setup
        let original = 1
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Int.self)
        
        /// When
        manager.applyTransformMiddlewares(original, [])
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertEqual(original, first)
    }
    
    public func test_middlewareDisabledRequest_shouldNotFireMiddlewares() {
        /// Setup
        let dummy: Try<Any> = Try.success(())
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = MockRequest.builder()
            .with(applyMiddlewares: false)
            .with(retries: 10)
            .build()
        
        let generator: HMRequestGenerator<Any,MockRequest> = {_ in
            Observable.just(Try.success(request))
        }
        
        let perform: (MockRequest) throws -> Observable<Try<Any>> = {_ in
            throw Exception("Error!")
        }
        
        // This request object should be nil if the middlewares are not called.
        var requestObject: MockRequest? = nil
        
        let rqMiddlewareManager: HMMiddlewareManager<MockRequest> =
            HMMiddlewareManager<MockRequest>.builder()
                .add(transform: {_ in throw Exception("Should not be fired") })
                .add(sideEffect: {_ in throw Exception("Should not be fired") })
                .add(sideEffect: { requestObject = $0 })
                .addLoggingMiddleware()
                .build()
        
        let handler = RequestHandler(requestMiddlewareManager: rqMiddlewareManager)
        
        /// When
        handler.execute(dummy, generator, perform)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertNil(requestObject)
    }
    
    public func test_requestMiddlewaresForNetworkRequest_shouldAddHeaders() {
        /// Setup
        let dummy: Try<Any> = Try.success(())
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(method: .get)
            .shouldApplyMiddlewares()
            .build()
        
        let generator: HMRequestGenerator<Any,HMNetworkRequest> = {_ in
            Observable.just(Try.success(request))
        }
        
        let processor: HMEQResultProcessor<Any> = HMResultProcessors.eqProcessor()
        let headers = ["Key1" : "Value1"]
        
        // We set this as a side effect to verify that the method was called.
        // In practice, never do this.
        var requestObject: HMNetworkRequest? = nil
        
        // Need to reset properties here because these are all structs
        let rqMiddlewareManager: HMMiddlewareManager<HMNetworkRequest> =
            HMMiddlewareManager<HMNetworkRequest>.builder()
                .add(transform: {
                    Observable.just($0.cloneBuilder().with(headers: headers).build())
                })
                .add(sideEffect: {
                    let rqHeaders = try! $0.headers()
                    XCTAssertEqual(headers, rqHeaders!)
                    requestObject = request
                })
                .build()
        
        let handler = HMNetworkRequestHandler.builder()
            .with(urlSession: URLSession.shared)
            .with(rqMiddlewareManager: rqMiddlewareManager)
            .build()

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
