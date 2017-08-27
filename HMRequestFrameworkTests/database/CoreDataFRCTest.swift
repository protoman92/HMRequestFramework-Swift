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
    
    deinit {
        print("Deinit \(self)")
    }
    
    override public func setUp() {
        super.setUp()
        iterationCount = 20
        dummyCount = 100
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
        var willChangeCount = 0
        var didChangeCount = 0
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
            .doOnNext({self.validateDidChange($0)})
            .doOnNext({self.validateInsert($0)})
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
    
    // For this test, we are introducing section events as well, so we need
    // to take care when comparing event counts.
    public func test_streamDBUpdateAndDeleteEvents_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        
        let frcRequest = dummy1FetchRequest()
            .cloneBuilder()
            .with(frcSectionName: "id")
            .build()
        
        let frc = try! manager.getFRCWrapperForRequest(frcRequest)
        let iterationCount = self.iterationCount!
        let dummyCount = self.dummyCount!
        var originalObjects: [Dummy1] = []
        
        // Call count is -1 initially to take care of first empty event. The
        // willChange and didChange counts will be higher than update count
        // because they apply to inserts and deletes as well.
        var callCount = -1
        var willChangeCount = 0
        var didChangeCount = 0
        var insertCount = 0
        var insertSectionCount = 0
        var updateCount = 0
        var updateSectionCount = 0
        var deleteCount = 0
        var deleteSectionCount = 0
        
        /// When
        frc.rx.startStream(Dummy1.self)
            .doOnNext({_ in callCount += 1})
            .doOnNext({
                switch $0 {
                case .willChange: willChangeCount += 1
                case .didChange: didChangeCount += 1
                case .insert: insertCount += 1
                case .insertSection: insertSectionCount += 1
                case .update: updateCount += 1
                case .updateSection: updateSectionCount += 1
                case .delete: deleteCount += 1
                case .deleteSection: deleteSectionCount += 1
                default: break
                }
            })
            .doOnNext({self.validateDidChange($0)})
            .doOnNext({self.validateInsert($0)})
            .doOnNext(self.validateInsertSection)
            .doOnNext({self.validateUpdate(
                $0,
                {!originalObjects.contains($0)},
                {obj in originalObjects.contains(where: {$0.id == obj.id})})
            })
            .doOnNext(self.validateUpdateSection)
            .doOnNext({self.validateDelete($0)})
            .doOnNext(self.validateDeleteSection)
            .cast(to: Any.self)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        self.upsertAndDelete({originalObjects.append(contentsOf: $0)},
                             {_ in},
                             {})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let currentObjects = frc.currentObjects(Dummy1.self)
        XCTAssertTrue(callCount > iterationCount)
        XCTAssertEqual(willChangeCount, iterationCount + 2)
        XCTAssertEqual(didChangeCount, iterationCount + 2)
        XCTAssertEqual(insertCount, dummyCount)
        XCTAssertEqual(insertSectionCount, dummyCount)
        XCTAssertEqual(updateCount, iterationCount * dummyCount)
        XCTAssertEqual(updateSectionCount, 0)
        XCTAssertEqual(deleteCount, dummyCount)
        XCTAssertEqual(deleteSectionCount, dummyCount)
        
        XCTAssertEqual(callCount, 0 +
            willChangeCount +
            didChangeCount +
            insertCount +
            insertSectionCount +
            updateCount +
            updateSectionCount +
            deleteCount +
            deleteSectionCount
        )
        
        XCTAssertEqual(currentObjects.count, 0)
    }
}

public extension CoreDataFRCTest {
    func validateDidChange(_ event: HMCDEvent<Dummy1>,
                           _ asserts: (([Dummy1]) -> Bool)...) {
        if case .didChange(let change) = event {
            let sections = change.sections
            let objects = change.objects
            XCTAssertTrue(asserts.map({$0(objects)}).all({$0}))
            
            if sections.isNotEmpty {
                let sectionObjects = sections.flatMap({$0.objects})
                XCTAssertEqual(sectionObjects.count, objects.count)
                XCTAssertTrue(objects.all(sectionObjects.contains))
            }
        }
    }
    
    func validateInsert(_ event: HMCDEvent<Dummy1>,
                        _ asserts: ((Dummy1) -> Bool)...) {
        if case .insert(let change) = event {
            XCTAssertNil(change.oldIndex)
            XCTAssertNotNil(change.newIndex)
            XCTAssertTrue(asserts.map({$0(change.object)}).all({$0}))
        }
    }
    
    func validateInsertSection(_ event: HMCDEvent<Dummy1>) {
        if case .insertSection(let change) = event {
            let sectionInfo = change.section
            XCTAssertEqual(sectionInfo.numberOfObjects, 1)
            XCTAssertTrue(sectionInfo.objects.count > 0)
        }
    }
    
    func validateUpdate(_ event: HMCDEvent<Dummy1>,
                        _ asserts: ((Dummy1) -> Bool)...) {
        if case .update(let change) = event {
            XCTAssertNotNil(change.oldIndex)
            XCTAssertNotNil(change.newIndex)
            XCTAssertTrue(asserts.map({$0(change.object)}).all({$0}))
        }
    }
    
    func validateUpdateSection(_ event: HMCDEvent<Dummy1>) {}
    
    func validateDelete(_ event: HMCDEvent<Dummy1>,
                        _ asserts: ((Dummy1) -> Bool)...) {
        if case .delete(let change) = event {
            XCTAssertNotNil(change.oldIndex)
            XCTAssertNil(change.newIndex)
            XCTAssertTrue(asserts.map({$0(change.object)}).all({$0}))
        }
    }
    
    func validateDeleteSection(_ event: HMCDEvent<Dummy1>) {
        if case .deleteSection(let change) = event {
            let sectionInfo = change.section
            XCTAssertEqual(sectionInfo.numberOfObjects, 0)
            XCTAssertEqual(sectionInfo.objects.count, 0)
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
                    .delay(0.2, scheduler: MainScheduler.instance)
            })
            .reduce((), accumulator: {_ in ()})
            .cast(to: Any.self)
    }
    
    func upsertAndDelete(_ onInsert: @escaping ([Dummy1]) -> Void,
                         _ onUpsert: @escaping ([Dummy1]) -> Void,
                         _ onDelete: @escaping () -> Void) -> Observable<Any> {
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let deleteContext = manager.disposableObjectContext()
        let iterationCount = self.iterationCount!
        let dummyCount = self.dummyCount!
        let original = (0..<dummyCount).map({_ in Dummy1()})
        let entity = try! Dummy1.CDClass.entityName()
        
        return manager.rx.savePureObjects(context, original)
            .flatMap({manager.rx.persistLocally()})
            .doOnNext({onInsert(original)})
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

                    return Observable
                        .concat(
                            manager.rx.construct(context, replace)
                                .flatMap({manager.rx.upsert(upsertCtx, entity, $0)})
                                .map(toVoid),
                            
                            manager.rx.persistLocally()
                        )
                        .reduce((), accumulator: {_ in ()})
                        .doOnNext({onUpsert(replace)})
                })
                .reduce((), accumulator: {_ in ()})
            })
            .flatMap({manager.rx.deleteIdentifiables(deleteContext, entity, original)})
            .flatMap({manager.rx.persistLocally()})
            .doOnNext(onDelete)
            .cast(to: Any.self)
    }
}
