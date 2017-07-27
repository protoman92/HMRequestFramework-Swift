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
    fileprivate let dummy: Try<Void> = Try.success(())
    fileprivate let timeout: TimeInterval = 100
    fileprivate var disposeBag: DisposeBag!
    fileprivate var handler: HMNetworkRequestHandler!
    fileprivate var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        handler = HMNetworkRequestHandler.builder().with(urlSession: .shared).build()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    public func test_responseProcessingFailed_shouldNotThrowError() {
        /// Setup
        let message = "Failed to process response"
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        
        let request = HMNetworkRequest.builder()
            .with(resource: MockResource.empty)
            .with(method: .get)
            .build()
        
        let generator: HMRequestGenerator<Void,HMNetworkRequestType> = {_ in
            Observable.just(Try<HMNetworkRequestType>.success(request))
        }
        
        /// When
        handler.execute(dummy, generator)
            .flatMap({(_) -> Observable<Try<Any>> in throw Exception(message) })
            .catchErrorJustReturn(Try<Any>.failure)
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
