//
//  CoreDataFRCTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 8/23/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import RxTest
import XCTest
import SwiftUtilities
@testable import HMRequestFramework

public final class CoreDataFRCTest: CoreDataRequestTest {
    var iterationCount: Int!
    
    override public func setUp() {
        super.setUp()
        iterationCount = 5
        dummyCount = 2
    }
    
    public func test_streamDBChangesWithFRCWrapper_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let frcObserver = scheduler.createObserver([Dummy1].self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let frcRequest = dummy1FetchRequest()
        let frc = try! manager.getFRCWrapperForRequest(frcRequest)
        var allDummies: [Dummy1] = []
        
        // Call count is 1 to take care of first empty event.
        var callCount = -1
        
        try! frc.startStream()
        
        /// When
        frc.pureObjectStream(Dummy1.self)
            .doOnNext({_ in callCount += 1})
            .doOnNext({XCTAssertTrue(allDummies.all($0.contains))})
            .subscribe(frcObserver)
            .disposed(by: disposeBag)
        
        insertNewObjects({allDummies.append(contentsOf: $0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertEqual(callCount, iterationCount)
    }
    
    public func test_streamDBChangesWithProcessor_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let frcObserver = scheduler.createObserver([Dummy1].self)
        let expect = expectation(description: "Should have completed")
        let processor = dbProcessor!.processor
        var allDummies: [Dummy1] = []
        
        // Call count is 1 to take care of first empty event.
        var callCount = -1
        
        /// When
        processor.streamDBChanges(Dummy1.self)
            .doOnNext({_ in callCount += 1})
            .map({(try? $0.getOrThrow()) ?? []})
            .doOnNext({XCTAssertTrue(allDummies.all($0.contains))})
            .subscribe(frcObserver)
            .disposed(by: disposeBag)
        
        insertNewObjects({allDummies.append(contentsOf: $0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertEqual(callCount, iterationCount)
    }
    
    func insertNewObjects(_ onSave: @escaping ([Dummy1]) -> Void) -> Observable<Any> {
        let manager = self.manager!
        let iterationCount = self.iterationCount!
        let dummyCount = self.dummyCount!
        
        return Observable
            .range(start: 0, count: iterationCount)
            .concatMap({(_) -> Observable<Void> in
                let context = manager.disposableObjectContext()
                let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
                
                return Observable
                    .concat(
                        manager.rx.savePureObjects(context, pureObjects),
                        manager.rx.persistLocally()
                    )
                    .reduce((), accumulator: {_ in ()})
                    .doOnNext({onSave(pureObjects)})
            })
            .reduce((), accumulator: {_ in ()})
            .cast(to: Any.self)
    }
}
