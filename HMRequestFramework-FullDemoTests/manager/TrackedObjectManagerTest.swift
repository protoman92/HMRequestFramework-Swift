//
//  TrackedObjectManagerTest.swift
//  HMRequestFramework-FullDemoTests
//
//  Created by Hai Pham on 18/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxSwift
import RxTest
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework_FullDemo

public final class TrackedObjectManagerTest: RootTest {}

public extension TrackedObjectManagerTest {
    public func test_multipleSavingOperations_shouldWorkCorrectly() {
        /// Setup
        let observer = scheduler.createObserver(User.self)
        let expect = expectation(description: "Should have completed")
        let disposeBag = self.disposeBag!
        let singleton = self.singleton!
        let rqManager = singleton.dbRequestManager
        let times = 100
        let qos: DispatchQoS.QoSClass = .background
        
        let users = (0..<times).map({_ in User.builder()
            .with(id: UUID().uuidString)
            .with(name: String.random(withLength: 10))
            .with(age: NSNumber(value: Int.randomBetween(0, 99)))
            .with(visible: NSNumber(value: Bool.random()))
            .build()
        })
        
        singleton.trackedObjectManager.dbUserStream()
            .mapNonNilOrEmpty()
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        /// When
        Observable.from(users)
            .flatMap({rqManager.upsertInMemory(Try.success([$0]), qos)
                .delay(0.2, scheduler: ConcurrentDispatchQueueScheduler(qos: qos))
            })
            .reduce(Try.success([]), accumulator: {$0.zipWith($1, +)})
            .doOnDispose(expect.fulfill)
            .subscribe()
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout!, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, users.count)
    }
}
