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
    fileprivate let dummy: Try<Any> = Try.success(())
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
            .with(rqMiddlewareManager: rqMiddlewareManager)
            .build()
        
        processor = HMNetworkRequestProcessor(handler: handler)
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    public func test_requestWithParams_shouldBeCorrectlyGenerated() {
        /// Setup
        let request = HMNetworkRequest.builder()
            .with(urlString: "https://google.com/image")
            .add(params: ["page": 1, "items": 5])
            .add(params: ["checked": true, "gotten": false])
            .with(operation: .get)
            .build()
        
        /// When & Then
        print(try! request.urlRequest().url!.absoluteString)
    }
    
    public func test_responseProcessingFailed_shouldNotThrowError() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(operation: .get)
            .build()
        
        let generator = HMRequestGenerators.forceGenerateFn(request, Any.self)
        
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
    
    public func test_uploadData_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Try<Data>.self)
        let expect = expectation(description: "Should have completed")
        let data = Data(count: 1)

        let request = Req.builder()
            .with(urlString: "https://google.com")
            .with(operation: .upload)
            .with(uploadData: data)
            .build()

        let generator = HMRequestGenerators.forceGenerateFn(request, Any.self)

        /// When
        handler.execute(dummy, generator)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertTrue(nextElements.count > 0)
    }
    
    public func test_networkRequestObject_shouldThrowErrorsIfNecessary() {
        var currentCheck = 0
        
        let checkError: (HMNetworkRequest, Bool) -> HMNetworkRequest = {
            currentCheck += 1
            let request = $0.0
            print("Checking request \(currentCheck): \(request)")
            
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
        let request2 = checkError(request1.cloneBuilder().with(urlString: "http://google.com").build(), true)
        
        /// 3
        let request3 = checkError(request2.cloneBuilder().with(operation: .get).build(), false)
        
        /// 4
        let request4 = checkError(request3.cloneBuilder().with(operation: .post).build(), true)
        
        /// 5
        let request5 = checkError(request4.cloneBuilder().with(operation: .put).build(), true)
        
        /// 6
        let request6 = checkError(request5.cloneBuilder().with(body: ["1" : "2"]).build(), false)
        
        /// 7
        let request7 = checkError(request6.cloneBuilder().with(operation: .upload).build(), true)
        
        /// 8
        let request8 = checkError(request7.cloneBuilder().with(uploadData: Data(capacity: 0)).build(), false)
        
        /// End
        _ = request8
    }
}
