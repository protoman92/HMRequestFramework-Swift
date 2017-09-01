//
//  RequestTest.swift
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

public final class RequestTest: RootTest {
    fileprivate typealias Req = RequestHandler.Req
    fileprivate var rqmManager: HMMiddlewareManager<Req>!
    fileprivate var handler: RequestHandler!
    
    override public func setUp() {
        super.setUp()
        rqmManager = HMMiddlewareManager<Req>.builder().build()
        handler = RequestHandler(requestMiddlewareManager: rqmManager)
    }
    
    public func test_requestGeneratorFailed_shouldNotThrowError() {
        /// Setup
        let message = "Failed to generate request"
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let generator: HMRequestGenerator<Any,MockRequest> = {
            _ in throw Exception(message)
        }
        
        let perform = HMRequestPerformers.eqPerformer(Any.self)
        
        /// When
        handler.execute(dummy, generator, perform)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 1)
        
        let tryElement = elements.first!
        XCTAssertTrue(tryElement.isFailure)
        
        let exception = tryElement.error!
        XCTAssertEqual(exception.localizedDescription, message)
    }
    
    public func test_invalidUpstreamResponse_shouldEmitOriginal() {
        /// Setup
        let message = "Invalid previous response"
        let previous = Try<Any>.failure(Exception(message))
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let generator1 = HMRequestGenerators.forceGn({(_: Any) -> Observable<MockRequest> in
            Observable.error("This error should be ignored")
        })
        
        let generator2: HMRequestGenerator<Any,MockRequest> = {
            _ in throw Exception(message)
        }
        
        let perform = HMRequestPerformers.eqPerformer(Any.self)
        
        /// When
        handler.execute(previous, generator1, perform)
            .flatMap({Observable.merge([
                self.handler.execute($0, generator2, perform),
                self.handler.execute($0, generator2, perform),
                self.handler.execute($0, generator2, perform)
            ])})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 3)
        
        for tryElement in elements {
            XCTAssertTrue(tryElement.isFailure)
            
            let exception = tryElement.error!
            XCTAssertEqual(exception.localizedDescription, message)
        }
    }
    
    public func test_processingFailedForSomeItems_shouldNotThrowError() {
        /// Setup
        let times = 10000
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        // Multiple requests
        let generator: HMRequestGenerator<Any,MockRequest> = {_ in
            return Observable.range(start: 0, count: times)
                .map({
                    if $0.isEven {
                        return Try.success(MockRequest.builder().build())
                    } else {
                        let error = Exception("Error")
                        return Try<MockRequest>.failure(error)
                    }
                })
        }
        
        // Multiple failures
        let perform: HMRequestPerformer<MockRequest,Any> = {
            Observable.just(Try<MockRequest>.success($0))
                .map({try $0.getOrThrow()})
                .flatMap({(request) -> Observable<MockRequest> in
                    if Bool.random() {
                        return Observable.just(request)
                    } else {
                        return Observable.error("Error!")
                    }
                })
                .cast(to: Any.self)
                .map(Try<Any>.success)
                .catchErrorJustReturn(Try<Any>.failure)
        }
        
        /// When
        handler.execute(dummy, generator, perform)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        XCTAssertEqual(observer.nextElements().count, times)
    }
}
