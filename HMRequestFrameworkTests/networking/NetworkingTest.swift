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
    
    public func test_networkRequestObject_shouldThrowErrorsIfNecessary() {
        var currentCheck = 0
        
        let checkError: (HMNetworkRequest, Bool) -> HMNetworkRequest = {
            currentCheck += 1
            print("Checking request \(currentCheck)")
            
            let request = $0.0
            
            do {
                _ = try request.urlRequest()
            } catch let e {
                print(e)
                XCTAssertTrue($0.1)
            }
            
            return request
        }
        
        /// 1
        let request1 = checkError(HMNetworkRequest.builder().build(), true)
        
        /// 2
        let request2 = checkError(request1.builder().with(baseUrl: "http://google.com").build(), true)
        
        /// 3
        let request3 = checkError(request2.builder().with(endPoint: "").build(), true)
        
        /// 4
        let request4 = checkError(request3.builder().with(method: .get).build(), false)
        
        /// 5
        let request5 = checkError(request4.builder().with(method: .post).build(), true)
        
        /// 6
        let request6 = checkError(request5.builder().with(method: .put).build(), true)
        
        /// 7
        let request7 = checkError(request6.builder().with(body: ["1" : "2"]).build(), false)
        
        /// End
        _ = request7
    }
}
