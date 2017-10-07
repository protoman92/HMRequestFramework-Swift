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

extension Int: HMMiddlewareFilterableType {
    public typealias Filterable = String
    
    public func middlewareFilters() -> [HMMiddlewareFilter<Int>] {
        return []
    }
}

public final class MiddlewareTest: RootTest {
    fileprivate var manager: HMFilterMiddlewareManager<Int>!
    
    override public func setUp() {
        super.setUp()
        manager = HMFilterMiddlewareManager<Int>.builder().build()
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
        let finalError = "This error should be thrown"
        
        // If we filter these middlewares out, we'd expect them not to be applied
        // to the request.
        let rqmManager = HMFilterMiddlewareManager<MockRequest>.builder()
            .add(transform: {_ in throw Exception("Error1") }, forKey: "middleware1")
            .add(transform: {_ in throw Exception("Error2") }, forKey: "middleware2")
            .add(transform: {_ in throw Exception(finalError)}, forKey: "middleware3")
            .build()
        
        let errManager = HMGlobalMiddlewareManager<HMErrorHolder>.builder().build()
        
        // Even if there are some error filters, they will not affect the other
        // filters.
        let request = MockRequest.builder()
            .add(mwFilter: HMMiddlewareFilters.excludingFilters("middleware1"))
            .add(mwFilter: HMMiddlewareFilters.excludingFilters("middleware2"))
            .with(applyMiddlewares: true)
            .build()
        
        let generator = HMRequestGenerators.forceGn(request, Any.self)
        let perform = HMRequestPerformers.eqPerformer(MockRequest.self)
        
        let handler = RequestHandler(rqMiddlewareManager: rqmManager,
                                     errMiddlewareManager: errManager)
        
        /// When
        handler.execute(Try.success(()), generator, perform, .background)
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertTrue(nextElements.count > 0)
        XCTAssertTrue(nextElements.all({$0.isFailure}))
        XCTAssertEqual(nextElements.first?.error?.localizedDescription, finalError)
    }
    
    public func test_filterMiddlewareFailedWithError_shouldInvalidateAllMiddlewares() {
        /// Setup
        let rqmManager = HMFilterMiddlewareManager<MockRequest>.builder()
            .add(transform: {_ in throw Exception("Error1")}, forKey: "middleware1")
            .add(transform: {_ in throw Exception("Error2")}, forKey: "middleware2")
            .add(transform: {_ in throw Exception("Error3")}, forKey: "middleware3")
            .build()
        
        let request = MockRequest.builder()
            .add(mwFilter: {_ in throw Exception("FilterError1")})
            .add(mwFilter: {_ in throw Exception("FilterError2")})
            .build()
        
        let tfMiddlewares = rqmManager.tfMiddlewares
        let seMiddlewares = rqmManager.seMiddlewares
        
        /// When
        let tfFiltered = rqmManager.filterMiddlewares(request, tfMiddlewares)
        let seFiltered = rqmManager.filterMiddlewares(request, seMiddlewares)
        
        /// Then
        XCTAssertEqual(tfFiltered.count, 0)
        XCTAssertEqual(seFiltered.count, 0)
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
        
        let rqmManager: HMFilterMiddlewareManager<MockRequest> =
            HMFilterMiddlewareManager<MockRequest>.builder()
                .add(transform: {_ in throw Exception("Should not be fired") }, forKey: "E1")
                .add(sideEffect: {_ in throw Exception("Should not be fired") }, forKey: "E2")
                .add(sideEffect: { requestObject = $0 }, forKey: "SE1")
                .build()
        
        let errManager = HMGlobalMiddlewareManager<HMErrorHolder>.builder().build()
        
        let handler = RequestHandler(rqMiddlewareManager: rqmManager,
                                     errMiddlewareManager: errManager)
        
        /// When
        handler.execute(dummy, generator, perform, .background)
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
        
        let generator: HMRequestGenerator<Any,HMNetworkRequest> = {_ in
            Observable.just(Try.success(request))
        }
        
        let processor = HMResultProcessors.eqProcessor(Any.self)
        let headers = ["Key1" : "Value1"]
        
        // We set this as a side effect to verify that the method was called.
        // In practice, never do this.
        var requestObject: HMNetworkRequest? = nil
        
        // Need to reset properties here because these are all structs
        let rqmManager: HMFilterMiddlewareManager<HMNetworkRequest> =
            HMFilterMiddlewareManager<HMNetworkRequest>.builder()
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
            .with(rqmManager: rqmManager)
            .build()

        let nwProcessor = HMNetworkRequestProcessor(handler: handler)
        
        /// When
        nwProcessor.process(dummy, generator, processor, .background)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertNotNil(requestObject)
    }
    
    public func test_errorMiddlewareManager_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let dummy = Try<Any>.success(())
        let mockRequest = MockRequest.builder().build()
        let generator = HMRequestGenerators.forceGn(mockRequest, Any.self)
        
        let perform: HMRequestPerformer<MockRequest,MockRequest> = {_ in
            throw Exception("Perform error!")
        }
        
        let rqmManager = HMFilterMiddlewareManager<MockRequest>.builder().build()
        
        let errManager = HMGlobalMiddlewareManager<HMErrorHolder>.builder()
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 1"))
                .build())})
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 2"))
                .build())})
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 3"))
                .build())})
            .add(sideEffect: {print($0)})
            .build()
        
        let handler = RequestHandler(rqMiddlewareManager: rqmManager,
                                     errMiddlewareManager: errManager)
        
        /// When
        handler.execute(dummy, generator, perform, .background)
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertTrue(first.isFailure)
        XCTAssertEqual(first.error?.localizedDescription, "Transformed 3")
    }
    
    public func test_applyErrorMiddlewaresFailed_shouldNotThrowError() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let dummy = Try<Any>.success(())
        let mockRequest = MockRequest.builder().build()
        let generator = HMRequestGenerators.forceGn(mockRequest, Any.self)
        
        let perform: HMRequestPerformer<MockRequest,MockRequest> = {_ in
            throw Exception("Perform error!")
        }
        
        let rqmManager = HMFilterMiddlewareManager<MockRequest>.builder().build()
        
        let errManager = HMGlobalMiddlewareManager<HMErrorHolder>.builder()
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 1"))
                .build())})
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 2"))
                .build())})
            .add(transform: {_ in throw Exception("Not possible!")})
            .add(transform: {Observable.just($0.cloneBuilder()
                .with(error: Exception("Transformed 3"))
                .build())})
            .build()
        
        let handler = RequestHandler(rqMiddlewareManager: rqmManager,
                                     errMiddlewareManager: errManager)
        
        /// When
        handler.execute(dummy, generator, perform, .background)
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertTrue(first.isFailure)
        XCTAssertEqual(first.error?.localizedDescription, "Not possible!")
    }
}
