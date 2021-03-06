//
//  NetworkingTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 6/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import Reachability
import RxSwift
import RxTest
import SwiftFP
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework

public final class NetworkingTest: RootTest, HMNetworkRequestAliasType {
  fileprivate typealias Req = HMNetworkRequestHandler.Req
  fileprivate var rqmManager: HMFilterMiddlewareManager<Req>!
  fileprivate var handler: HMNetworkRequestHandler!
  fileprivate var processor: HMNetworkRequestProcessor!

  override public func setUp() {
    super.setUp()
    rqmManager = HMFilterMiddlewareManager<Req>.builder().build()

    handler = HMNetworkRequestHandler.builder()
      .with(urlSession: .shared)
      .with(rqmManager: rqmManager)
      .build()

    processor = HMNetworkRequestProcessor(handler: handler)
  }
}

public extension NetworkingTest {
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

  public func test_networkRequestObject_shouldThrowErrorsIfNecessary() {
    var currentCheck = 0

    let checkError: (HMNetworkRequest, Bool) -> HMNetworkRequest = {
      currentCheck += 1
      let request = $0
      print("Checking request \(currentCheck): \(request)")

      do {
        _ = try request.urlRequest()
      } catch let e {
        print(e)
        XCTAssertTrue($1)
      }

      return request
    }

    /// 1
    let request1 = checkError(HMNetworkRequest.builder().build(), true)

    /// 2
    let request2 = checkError(request1.cloneBuilder()
      .with(urlString: "http://google.com")
      .build(), true)

    /// 3
    let request3 = checkError(request2.cloneBuilder()
      .with(operation: .get)
      .build(), false)

    /// 4
    let request4 = checkError(request3.cloneBuilder()
      .with(operation: .post)
      .build(), true)

    /// 5
    let request5 = checkError(request4.cloneBuilder()
      .with(operation: .put)
      .build(), true)

    /// 6
    let request6 = checkError(request5.cloneBuilder()
      .with(body: ["1" : "2"])
      .build(), false)

    /// 7
    let request7 = checkError(request6.cloneBuilder()
      .with(uploadData: Data(capacity: 0))
      .build(), false)

    /// End
    _ = request7
  }
}

public extension NetworkingTest {
  public func test_responseProcessingFailed_shouldNotThrowError() {
    /// Setup
    let observer = scheduler.createObserver(Try<Any>.self)
    let expect = expectation(description: "Should have completed")

    let request = HMNetworkRequest.builder()
      .with(resource: MockResource.empty)
      .with(baseUrl: "www.google.com")
      .with(operation: .get)
      .build()

    let generator = HMRequestGenerators.forceGn(request, Any.self)

    let processor: HMResultProcessor<Any,Any> = {_ in
      throw Exception("Error!")
    }

    /// When
    self.processor.process(dummy, generator, processor, .background)
      .doOnDispose(expect.fulfill)
      .subscribe(observer)
      .disposed(by: disposeBag)

    waitForExpectations(timeout: timeout, handler: nil)

    /// Then
    let elements = observer.nextElements()
    print(observer.events)
    print(elements)
    XCTAssertEqual(elements.count, 1)
    XCTAssertTrue(elements.first?.isFailure ?? false)
  }
}

public extension NetworkingTest {
  public func test_uploadData_shouldWork() {
    guard Reachability()!.connection != .none else { return }
    typealias UploadResult = HMNetworkRequestAliasType.UploadResult

    /// Setup
    let observer = scheduler.createObserver(Try<UploadResult>.self)
    let expect = expectation(description: "Should have completed")
    let nwProcessor = self.processor!
    let data = Data(count: 1)

    let request = Req.builder()
      .with(urlString: "https://google.com")
      .with(operation: .put)
      .with(uploadData: data)
      .build()

    let generator = HMRequestGenerators.forceGn(request, Any.self)
    let processor = HMResultProcessors.eqProcessor(UploadResult.self)
    let qos: DispatchQoS.QoSClass = .background

    /// When
    nwProcessor.processUpload(Try.success(()), generator, processor, qos)
      .doOnDispose(expect.fulfill)
      .subscribe(observer)
      .disposed(by: disposeBag)

    waitForExpectations(timeout: timeout, handler: nil)

    /// Then
    let nextElements = observer.nextElements()
    XCTAssertTrue(nextElements.count > 0)
    XCTAssertTrue(nextElements.all({$0.isSuccess}))
  }
}
