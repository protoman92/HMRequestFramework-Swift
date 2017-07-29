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
    fileprivate var rqMiddlewares: [HMRequestMiddleware<Int>]!
    fileprivate var scheduler: TestScheduler!
    fileprivate var disposeBag: DisposeBag!
    
    override public func setUp() {
        super.setUp()
        rqMiddlewares = []
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }
    
    public func test_applyValidMiddlewares_shouldWork() {
        /// Setup
        let times = 1000
        
        let times2: HMRequestMiddleware<Int> = {
            Observable.just($0.map({$0 * 2}))
        }
        
        let times3: HMRequestMiddleware<Int> = {
            Observable.just($0.map({$0 * 3}))
        }
        
        let times4: HMRequestMiddleware<Int> = {
            Observable.just($0.map({$0 * 4}))
        }

        let middlewares = [times2, times3, times4]
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Any.self)
        
        /// When
        Observable.range(start: 0, count: times)
            .flatMap({i in self
                .applyMiddlewares(Try.success(i), middlewares)
                .map({try $0.getOrThrow()})
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
    
    public func test_applyEmptyMiddlewares_shouldReturnOriginal() {
        /// Setup
        let original = Try.success(1)
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Int>.self)
        
        /// When
        applyMiddlewares(original, [])
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertTrue(first.isSuccess)
        XCTAssertEqual(original.value, first.value)
    }
    
    public func test_applyErrorMiddlewares_shouldNotThrowError() {
        /// Setup
        let original = Try.success(1)
        
        let error1: HMRequestMiddleware<Int> = {_ in
            throw Exception("Error1")
        }
        
        let error2: HMRequestMiddleware<Int> = {_ in
            throw Exception("Error2")
        }
        
        let error3: HMRequestMiddleware<Int> = {_ in
            Observable.error("Error3")
        }
        
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Int>.self)
        
        /// When
        applyMiddlewares(original, [error1, error2, error3])
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        print(nextElements)
    }
}

extension MiddlewareTest: HMMiddlewareManagerType {
    public func middlewares() -> [HMRequestMiddleware<Int>] {
        return rqMiddlewares
    }
}
