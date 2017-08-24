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
    
    public func test_streamDBObjectsWithFRCWrapper_shouldWork() {
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
        
        try! frc.rx.startStream()
        
        /// When
        frc.rx.stream(Dummy1.self)
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
    
    public func test_streamDBObjectsWithProcessor_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let frcObserver = scheduler.createObserver([Dummy1].self)
        let expect = expectation(description: "Should have completed")
        let processor = self.dbProcessor!
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
    
    public func test_streamDBChanges_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let frcRequest = dummy1FetchRequest()
        let frc = try! manager.getFRCWrapperForRequest(frcRequest)
        
        try! frc.rx.startStream()
        
        /// When
        insertAndUpdate({_ in})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
    }
}

public extension CoreDataFRCTest {
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
    
    func insertAndUpdate(_ onUpsert: @escaping ([Dummy1]) -> Void) -> Observable<Any> {
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let iterationCount = self.iterationCount!
        let dummyCount = self.dummyCount!
        let original = (0..<dummyCount).map({_ in Dummy1()})
        let entityName = try! Dummy1.CDClass.entityName()
        
        return manager.rx.savePureObjects(context, original)
            .flatMap({manager.rx.persistLocally()})
            .flatMap({Observable.range(start: 0, count: iterationCount)
                .concatMap({(_) -> Observable<Void> in
                    let context = manager.disposableObjectContext()
                    let upsertCtx = manager.disposableObjectContext()
                    
                    let replace = (0..<dummyCount).map({(i) -> Dummy1 in
                        let previous = original[i]
                        let dummy = Dummy1()
                        dummy.id = previous.id
                        return dummy
                    })
                    
                    let cdReplace = try! manager.constructUnsafely(context, replace)

                    return Observable
                        .concat(
                            manager.rx.upsert(upsertCtx, entityName, cdReplace).logNext().map(toVoid),
                            manager.rx.persistLocally()
                        )
                        .reduce((), accumulator: {_ in ()})
                        .doOnNext({onUpsert(replace)})
                })
                .reduce((), accumulator: {_ in ()})
            })
            .cast(to: Any.self)
    }
}
