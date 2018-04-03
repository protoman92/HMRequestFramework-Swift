//
//  CoreDataTextSearchTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 25/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftFP
import XCTest
@testable import HMRequestFramework

public final class CoreDataTextSearchTest: CoreDataRootTest {
  public func test_textSearchRequest_shouldBeCreatedCorrectly() {
    /// Setup
    let rq1 = HMCDTextSearchRequest.builder()
      .with(key: "Key1")
      .with(value: "Value1")
      .with(comparison: .contains)
      .add(modifier: .caseInsensitive)
      .add(modifier: .diacriticInsensitive)
      .build()

    /// When
    let predicate = try! rq1.textSearchPredicate()

    /// Then
    XCTAssertEqual(predicate.predicateFormat, "Key1 CONTAINS[cd] \"Value1\"")
  }

  public func test_fetchWithTextSearch_shouldWork(
    _ comparison: HMCDTextSearchRequest.Comparison,
    _ modifyText: (String, String) -> String,
    _ validate: (String, [Dummy1]) -> Void)
  {
    /// Setup
    let observer = scheduler.createObserver(Dummy1.self)
    let expect = expectation(description: "Should have completed")
    let dbProcessor = self.dbProcessor!
    let dummyCount = self.dummyCount!
    let additional = "viethai.pham"

    let requests: [HMCDTextSearchRequest] = [
      HMCDTextSearchRequest.builder()
        .with(key: "id")
        .with(value: additional)
        .with(comparison: comparison)
        .with(modifiers: [.caseInsensitive, .diacriticInsensitive])
        .build(),
      ]

    let dummies = (0..<dummyCount).map({_ -> Dummy1 in
      let dummy = Dummy1()

      if Bool.random() {
        let oldId = dummy.id!
        let newId = modifyText(oldId, additional)
        return dummy.cloneBuilder().with(id: newId).build()
      } else {
        return dummy
      }
    })

    let qos: DispatchQoS.QoSClass = .background

    _ = try! dbProcessor
      .saveToMemory(Try.success(dummies), qos)
      .toBlocking()
      .first()

    /// When
    dbProcessor
      .fetchWithTextSearch(Try.success(()), Dummy1.self, requests, .and, qos)
      .map({try $0.getOrThrow()})
      .flattenSequence()
      .doOnDispose(expect.fulfill)
      .subscribe(observer)
      .disposed(by: disposeBag)

    waitForExpectations(timeout: timeout, handler: nil)

    /// Then
    let nextElements = observer.nextElements()
    XCTAssertTrue(!nextElements.isEmpty)
    validate(additional, nextElements)

    print(nextElements.flatMap({$0.id}))
  }

  public func test_fetchWithContains_shouldWork() {
    test_fetchWithTextSearch_shouldWork(
      .contains, {"\($0)\($1)"},
      {(text, dummies) in XCTAssertTrue(dummies.all({$0.id!.contains(text)}))})
  }

  public func test_fetchWithBeginsWith_shouldWork() {
    test_fetchWithTextSearch_shouldWork(
      .contains, {"\($1)\($0)"},
      {(text, dummies) in XCTAssertTrue(dummies.all({$0.id!.starts(with: text)}))})
  }
}
