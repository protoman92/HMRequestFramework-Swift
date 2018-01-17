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
        let disposeBag = self.disposeBag!
        let singleton = self.singleton!
        let rqManager = singleton.dbRequestManager
        let times = 5
        let qos: DispatchQoS.QoSClass = .background
        
        let users = (0..<times).map({User.builder()
            .with(id: UUID().uuidString)
            .with(name: String.random(withLength: 10))
            .with(age: NSNumber(value: Int.randomBetween(0, 99)))
            .with(visible: NSNumber(value: Bool.random()))
            .with(updatedAt: Date().addingTimeInterval(Double($0 * 100000)))
            .build()
        })
        
        users.forEach({print($0)})
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        
        singleton.trackedObjectManager.dbUserStream()
            .mapNonNilOrEmpty()
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        /// When
        let saveOps = users.enumerated().map({(i, user) -> () -> Void in {
            background(closure: {
                let prev = Try.success([user])
                let delay = Double(i) / 50
                let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
                print("Delay: \(delay) for \(user)")
                
                Observable.just(())
                    .delay(delay, scheduler: scheduler)
                    .flatMap({_ in rqManager.upsertInMemory(prev, qos)})
                    .map({$0.map(toVoid)})
                    .subscribe()
                    .disposed(by: disposeBag)
            })
        }})
        
        saveOps.forEach({$0()})
        waitOnMainThread(Double(times) * 0.2)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements, users)
    }
}
