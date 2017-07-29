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

public final class RequestTest: XCTestCase {
    fileprivate let dummy: Try<Any> = Try.success(())
    fileprivate let timeout: TimeInterval = 100
    fileprivate var rqMiddlewareManager: HMMiddlewareManager<Req>!
    fileprivate var disposeBag: DisposeBag!
    fileprivate var handler: RequestTest!
    fileprivate var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        rqMiddlewareManager = HMMiddlewareManager<Req>.builder().build()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        handler = self
    }
    
    public func test_requestGeneratorFailed_shouldNotThrowError() {
        /// Setup
        let message = "Failed to generate request"
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let generator: HMRequestGenerator<Any,MockRequest> = {
            _ in throw Exception(message)
        }
        
        let perform: (Any) throws -> Observable<Try<Any>> = {
            return Observable.just(Try.success($0))
        }
        
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
        
        let generator1 = HMRequestGenerators.forceGenerateFn(generator: {
            (_: Any) -> Observable<MockRequest> in
            Observable.error("This error should be ignored")
        })
        
        let generator2: HMRequestGenerator<Any,MockRequest> = {
            _ in throw Exception(message)
        }
        
        let perform: (Any) throws -> Observable<Try<Any>> = {
            return Observable.just(Try.success($0))
        }
        
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
        let perform: (MockRequest) -> Observable<Try<Any>> = {
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

extension RequestTest: HMRequestHandlerType {
    public typealias Req = MockRequest
    
    public func requestMiddlewareManager() -> HMMiddlewareManager<Req> {
        return rqMiddlewareManager
    }
}

public struct MockRequest {
    fileprivate var retryCount: Int
    
    fileprivate init() {
        retryCount = 0
    }
}

extension MockRequest: HMRequestType {
    public func retries() -> Int {
        return retryCount
    }
}

fileprivate extension MockRequest {
    static func builder() -> Builder {
        return Builder()
    }
    
    fileprivate class Builder {
        fileprivate var request: MockRequest
        
        init() {
            request = MockRequest()
        }
        
        @discardableResult
        func with(retries: Int) -> Builder {
            request.retryCount = retries
            return self
        }
        
        func build() -> MockRequest {
            return request
        }
    }
}
