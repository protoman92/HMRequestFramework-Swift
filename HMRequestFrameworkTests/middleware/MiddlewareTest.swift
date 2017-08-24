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

extension Int: HMValueFilterableType {
    public func valueFilters() -> [HMValueFilter<Int,String>] {
        return []
    }
}

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
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let times = 1000
        let middleware1: HMTransformMiddleware<Int> = {Observable.just($0 * 2)}
        let middleware2: HMTransformMiddleware<Int> = {Observable.just($0 * 3)}
        let middleware3: HMTransformMiddleware<Int> = {Observable.just($0 * 4)}

        let middlewares = [
            ("middleware1", middleware1),
            ("middleware2", middleware2),
            ("middleware3", middleware3)
        ]
        
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
    
    public func test_filterMiddlewaresWithFilterables_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        // If we filter these middlewares out, we'd expect them not to be applied
        // to the request.
        let rqMiddlewareManager = HMMiddlewareManager<MockRequest>.builder()
            .add(transform: {_ in throw Exception("Error1") }, forKey: "middleware1")
            .add(transform: {_ in throw Exception("Error2") }, forKey: "middleware2")
            .build()
        
        let request = MockRequest.builder()
            .with(valueFilters: [
                MockRequest.MiddlewareFilter({$0.1 != "middleware1"}),
                MockRequest.MiddlewareFilter({$0.1 != "middleware2"})
            ])
            .with(applyMiddlewares: true)
            .build()
        
        let generator = HMRequestGenerators.forceGn(request, Any.self)
        
        let perform: (MockRequest) throws -> Observable<Try<Void>> = {_ in
            return Observable.just(Try.success(()))
        }
        
        let handler = RequestHandler(requestMiddlewareManager: rqMiddlewareManager)
        
        /// When
        handler.execute(Try.success(()), generator, perform)
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertTrue(nextElements.count > 0)
        
        // Since all the middlewares throw errors, if they are applied, the
        // final result will be a failure Try.
        XCTAssertTrue(nextElements.all({$0.isSuccess}))
    }
    
    public func test_applyEmptyTransformMiddlewares_shouldReturnOriginal() {
        /// Setup
        let observer = scheduler.createObserver(Int.self)
        let expect = expectation(description: "Should have completed")
        let original = 1
        
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
    
    public func test_disableMiddlewaresForRequest_shouldNotFireMiddlewares() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let dummy: Try<Any> = Try.success(())
        
        let request = MockRequest.builder()
            .with(applyMiddlewares: false)
            .with(retries: 10)
            .build()
        
        let generator = HMRequestGenerators.forceGn(request, Any.self)
        
        let perform: (MockRequest) throws -> Observable<Try<Any>> = {_ in
            throw Exception("Error!")
        }
        
        // This request object should be nil if the middlewares are not called.
        var requestObject: MockRequest? = nil
        
        let rqMiddlewareManager: HMMiddlewareManager<MockRequest> =
            HMMiddlewareManager<MockRequest>.builder()
                .add(transform: {_ in throw Exception("Should not be fired") }, forKey: "E1")
                .add(sideEffect: {_ in throw Exception("Should not be fired") }, forKey: "E2")
                .add(sideEffect: { requestObject = $0 }, forKey: "SE1")
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
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let dummy: Try<Any> = Try.success(())
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(operation: .get)
            .shouldApplyMiddlewares()
            .build()
        
        let generator: HMAnyRequestGenerator<HMNetworkRequest> = {_ in
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
                    Observable.just($0.cloneBuilder()
                        .with(headers: headers)
                        .build())
                }, forKey: "TF1")
                .add(sideEffect: {
                    let rqHeaders = $0.headers()
                    XCTAssertEqual(headers, rqHeaders!)
                    requestObject = request
                }, forKey: "SE1")
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
