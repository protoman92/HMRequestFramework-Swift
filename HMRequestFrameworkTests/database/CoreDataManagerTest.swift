//
//  CoreDataManagerTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import RxBlocking
import RxTest
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework

public final class CoreDataManagerTest: CoreDataRootTest {
    public func test_constructBuildable_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy2.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummies = (0..<10000).map({_ in Dummy2()})
        
        /// When
        manager.rx.construct(context, dummies)
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .map({$0.asPureObject()})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
            
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(dummies, nextElements)
    }
    
    public func test_saveAndFetchBuildable_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: ("Should have completed"))
        let dummyCount = self.dummyCount!
        let manager = self.manager!
        let dummies = (0..<dummyCount).map({_ in Dummy1()})
        let fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        
        // Different contexts for each operation.
        let saveContext = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        // Save the dummies in memory. Their NSManagedObject equivalents will
        // be constructed here.
        manager.rx.savePureObjects(saveContext, dummies)
            
            // Perform a fetch to verify that the data have been inserted, but
            // not persisted.
            .flatMap({manager.rx.fetch(fetchContext1, fetchRq).subscribeOnConcurrent(qos: .background)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .map(toVoid)
            
            // Persist the data.
            .flatMap({manager.rx.persistLocally()})
            
            // Fetch the data and verify that they have been persisted.
            .flatMap({manager.rx.fetch(fetchContext2, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
        XCTAssertTrue(nextElements.all(dummies.contains))
    }
}

public extension CoreDataManagerTest {
    public func test_refetchUpsertables_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).flatMap({_ in Dummy1()})
        let cdObjects = try! manager.constructUnsafely(context, pureObjects)
        let entityName = try! Dummy1.CDClass.entityName()
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let refetchContext = manager.disposableObjectContext()

        /// When
        // Save data without persisting to DB.
        manager.rx.savePureObjects(saveContext, pureObjects)

            // Persist data to DB.
            .flatMap({_ in manager.rx.persistLocally()})

            // Refetch based on identifiable objects. We expect the returned
            // data to contain the same properties.
            .flatMap({manager.rx.fetchIdentifiables(refetchContext, entityName, cdObjects)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
        XCTAssertTrue(nextElements.all(pureObjects.contains))
    }
    
    public func test_insertAndDeleteUpsertables_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.CDClass.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        
        // Two contexts for two operations, no shared context.
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount!
        let pureObjects1 = (0..<dummyCount).map({_ in Dummy1()})
        
        let pureObjects2 = (0..<dummyCount).flatMap({(i) -> Dummy1 in
            let dummy = Dummy1()
            dummy.id = pureObjects1[i].id
            return dummy
        })
        
        let cdObjects1 = try! manager.constructUnsafely(context, pureObjects1)
        let cdObjects2 = try! manager.constructUnsafely(context, pureObjects2)
        
        let fetchRq = try! Req.builder()
            .with(poType: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .build()
            .fetchRequest(Dummy1.CDClass.self)
        
        let entityName = fetchRq.entityName!
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let deleteContext = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        // Save data1 to memory without persisting to DB.
        manager.rx.saveConvertibles(saveContext, cdObjects1)
            
            // Persist changes to DB. At this stage, data1 is the only set
            // of data within the DB.
            .flatMap({_ in manager.rx.persistLocally()})
            
            // Fetch to verify that the DB only contains data1.
            .flatMap({manager.rx.fetch(fetchContext1, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .doOnNext({XCTAssertTrue($0.all(pureObjects1.contains))})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            
            // Delete data2 from memory. data1 and data2 are two different
            // sets of data that only have the same primary key-value.
            .flatMap({_ in manager.rx.deleteIdentifiables(deleteContext,
                                                          entityName,
                                                          cdObjects2)})
            
            // Persist changes to DB.
            .flatMap({manager.rx.persistLocally()})
            
            // Fetch to verify that the DB is now empty.
            .flatMap({manager.rx.fetch(fetchContext2, fetchRq)})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
}

public extension CoreDataManagerTest {
    public func test_insertAndDeleteByBatch_shouldWork() {
        let manager = self.manager!
        
        // This does not work for in-memory store.
        if manager.areAllStoresInMemory() {
            return
        }
        
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let fetchRequest = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        let deleteRequest = try! dummy1FetchRequest().untypedFetchRequest()
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let deleteContext = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        manager.rx.savePureObjects(saveContext, pureObjects)
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext1, fetchRequest)})
            .map({$0.map({$0.asPureObject()})})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            .flatMap({_ in manager.rx.delete(deleteContext, deleteRequest)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({_ in manager.rx.fetch(fetchContext2, fetchRequest)})
            .map({$0.map({$0.asPureObject()})})
            .flattenSequence()
            .cast(to: Any.self)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_insertAndDeleteManyRandomDummies_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let iterationCount = 10
        let dummyCount = 100
        let request = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        let entityName = request.entityName!
        
        // Different contexts
        let fetchContext1 = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        Observable.from(0..<iterationCount)

            // For each iteration, create a bunch of dummies in a disposable
            // context and save them in memory. The main context should then
            // own the changes.
            .flatMap({(i) -> Observable<Void> in
                // Always beware that if we don't keep a reference to the
                // context, CD objects may lose their data.
                let sc1 = manager.disposableObjectContext()
                
                return Observable<[Dummy1]>
                    .create({
                        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
                        $0.onNext(pureObjects)
                        $0.onCompleted()
                        return Disposables.create()
                    })
                    .flatMap({manager.rx.savePureObjects(sc1, $0)})
                    .map(toVoid)
                    .subscribeOnConcurrent(qos: .background)
            })
            .reduce((), accumulator: {_ in ()})

            // Persist all changes to DB.
            .flatMap({manager.rx.persistLocally()})

            // Fetch to verify that the data have been persisted.
            .flatMap({manager.rx.fetch(fetchContext1, request)})
            .doOnNext({XCTAssertEqual($0.count, iterationCount * dummyCount)})
            .doOnNext({XCTAssertTrue($0.flatMap({$0.id}).count > 0)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({(objects) -> Observable<Void> in
                let sc = manager.disposableObjectContext()
                return manager.rx.deleteIdentifiables(sc, entityName, objects)
            })

            // Persist the changes.
            .flatMap({manager.rx.persistLocally()})

            // Fetch to verify that the data have been deleted.
            .flatMap({manager.rx.fetch(fetchContext2, request).subscribeOnConcurrent(qos: .background)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .cast(to: Any.self)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 0)
    }
}

public extension CoreDataManagerTest {
    public func test_predicateForIdentifiableFetch_shouldWork() {
        /// Setup
        let times = 100
        let pureObjs1 = (0..<times).map({_ in Dummy1()})
        let pureObjs2 = (0..<times).map({_ in Dummy2()})
        
        let allUpsertables = [
            pureObjs1.map({$0 as HMIdentifiableType}),
            pureObjs2.map({$0 as HMIdentifiableType})
        ].flatMap({$0})
        
        /// When
        let predicate = manager.predicateForIdentifiableFetch(allUpsertables)
        
        /// Then
        let description = predicate.description
        XCTAssertTrue(description.contains("IN"))
        XCTAssertTrue(description.contains("OR"))
    }
}

public extension CoreDataManagerTest {
    public func test_saveConvertiblesToDB_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let convertibles = try! manager.constructUnsafely(context, pureObjects)
        let fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()
        
        /// When
        // The convertible objects should be converted into their NSManagedObject
        // counterparts here. Even if we do not have access to the context that
        // created these objects, we can reconstruct them and insert into another
        // context of choice.
        manager.rx.saveConvertibles(saveContext, convertibles)
            .doOnNext({XCTAssertTrue($0.all({$0.isSuccess()}))})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, pureObjects.count)
        XCTAssertTrue(pureObjects.all(nextElements.contains))
    }
    
    public func test_upsertConvertibles_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount!
        let originalPureObjects = (0..<dummyCount).map({_ in Dummy1()})
        
        let editedPureObjects = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            dummy.id = originalPureObjects[i].id
            return dummy
        })
        
        let newPureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let upsertedPureObjects = [editedPureObjects, newPureObjects].flatMap({$0})
        let upsertedCDObjects = try! manager.constructUnsafely(context, upsertedPureObjects)
        let fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        let entityName = fetchRq.entityName!
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let upsertContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()
        
        /// When
        manager.rx.savePureObjects(saveContext, originalPureObjects)
            .flatMap({_ in manager.rx.persistLocally()})
            
            // We expect the edited data to overwrite, while new data will
            // simply be inserted.
            .flatMap({_ in manager.rx.upsert(upsertContext, entityName, upsertedCDObjects)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, upsertedPureObjects.count)
        XCTAssertTrue(upsertedPureObjects.all(nextElements.contains))
    }
}

public extension CoreDataManagerTest {
    public func test_fetchLimit_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let dummyCount = self.dummyCount!
        let limit = dummyCount / 2
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})

        let fetchRq = try! dummy1FetchRequest().cloneBuilder()
            .with(fetchLimit: limit)
            .build()
            .fetchRequest(Dummy1.self)

        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()

        /// When
        manager.rx.savePureObjects(saveContext, pureObjects)
            .flatMap({_ in manager.rx.persistLocally()})

            // We expect the number of results returned by this fetch to be
            // limited to the predefined fetchLimit.
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, limit)
        XCTAssertTrue(nextElements.all(pureObjects.contains))
    }
}

public extension CoreDataManagerTest {
    public func test_resetCDStack_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        
        // Different contexts
        let saveContext1 = manager.disposableObjectContext()
        let saveContext2 = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        let fetchContext3 = manager.disposableObjectContext()
        
        /// When
        // Save the pure objects once then check that they are in the DB.
        manager.rx.savePureObjects(saveContext1, pureObjects)
            .flatMap({manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext1, fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            
            // Reset the stack, then do another fetch to confirm DB is empty.
            .flatMap({_ in manager.rx.resetStack()})
            .flatMap({manager.rx.fetch(fetchContext2, fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, 0)})
            
            // Save the pure objects again to ensure the DB is reset correctly.
            .flatMap({_ in manager.rx.savePureObjects(saveContext2, pureObjects)})
            .flatMap({manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext3, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
        XCTAssertTrue(pureObjects.all(nextElements.contains))
    }
}
