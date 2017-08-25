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

public final class CoreDataFRCTest: CoreDataRootTest {
    var iterationCount: Int!
    
    override public func setUp() {
        super.setUp()
        iterationCount = 5
        dummyCount = 2
    }
    
    public func test_streamDBInsertsWithProcessor_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let frcObserver = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let processor = self.dbProcessor!
        let iterationCount = self.iterationCount!
        var allDummies: [Dummy1] = []
        
        // Call count is -1 initially to take care of first empty event.
        var callCount = -1
        var didChangeCount = 0
        var willChangeCount = 0
        var insertCount = 0
        
        /// When
        processor.streamDBEvents(Dummy1.self)
            .doOnNext({_ in callCount += 1})
            .map({try $0.getOrThrow()})
            .doOnNext({
                switch $0 {
                case .didChange: didChangeCount += 1
                case .willChange: willChangeCount += 1
                case .insert: insertCount += 1
                default: break
                }
            })
            .doOnNext({self.validateDidChange($0, {allDummies.all($0.contains)})})
            
            // The insert event is broadcast before didChange, so allDummies
            // do not contain the inner object yet.
            .doOnNext({self.validateInsert($0, {!allDummies.contains($0)})})
            .cast(to: Any.self)
            .subscribe(frcObserver)
            .disposed(by: disposeBag)
        
        insertNewObjects({allDummies.append(contentsOf: $0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertTrue(callCount >= iterationCount)
        XCTAssertEqual(didChangeCount, iterationCount)
        XCTAssertEqual(willChangeCount, iterationCount)
        XCTAssertEqual(callCount, didChangeCount + willChangeCount + insertCount)
    }
    
    public func test_streamDBInsertsWithFRCWrapper_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let frcObserver = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let frcRequest = dummy1FetchRequest()
        let frc = try! manager.getFRCWrapperForRequest(frcRequest)
        let iterationCount = self.iterationCount!
        var allDummies: [Dummy1] = []
        
        // Call count is -1 initially to take care of first empty event.
        var callCount = -1
        var didChangeCount = 0
        var willChangeCount = 0
        var insertCount = 0
        
        try! frc.rx.startStream()
        
        /// When
        frc.rx.streamEvents(Dummy1.self)
            .doOnNext({_ in callCount += 1})
            .doOnNext({
                switch $0 {
                case .didChange: didChangeCount += 1
                case .willChange: willChangeCount += 1
                case .insert: insertCount += 1
                default: break
                }
            })
            .doOnNext({print(allDummies, $0)})
            .doOnNext({self.validateDidChange($0, {allDummies.all($0.contains)})})
            
            // The insert event is broadcast before didChange, so allDummies
            // do not contain the inner object yet.
            .doOnNext({self.validateInsert($0, {!allDummies.contains($0)})})
            .cast(to: Any.self)
            .subscribe(frcObserver)
            .disposed(by: disposeBag)
        
        insertNewObjects({allDummies.append(contentsOf: $0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        XCTAssertTrue(callCount >= iterationCount)
        XCTAssertEqual(didChangeCount, iterationCount)
        XCTAssertEqual(willChangeCount, iterationCount)
        XCTAssertEqual(callCount, didChangeCount + willChangeCount + insertCount)
    }
    
    public func test_streamDBChangeEvents_shouldWork() {
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
    func validateDidChange(_ event: HMCDEvent<Dummy1>,
                           _ asserts: (([Dummy1]) -> Bool)...) {
        if case .didChange(let objects) = event {
            XCTAssertTrue(asserts.map({$0(objects)}).all({$0}))
        }
    }
    
    func validateInsert(_ event: HMCDEvent<Dummy1>,
                        _ asserts: ((Dummy1) -> Bool)...) {
        if case .insert(let object, let change) = event {
            XCTAssertNil(change.oldIndex)
            XCTAssertNotNil(change.newIndex)
            XCTAssertTrue(asserts.map({$0(object)}).all({$0}))
        }
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
