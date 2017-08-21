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
            .flatMap({Observable.from($0)})
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
        let observer = scheduler.createObserver(Dummy2.self)
        let expect = expectation(description: ("Should have completed"))
        let dummyCount = self.dummyCount
        let manager = self.manager!
        let mainContext = manager.mainContext
        let privateContext = manager.privateContext
        let dummies = (0..<dummyCount).map({_ in Dummy2()})
        let fetchRq: NSFetchRequest<CDDummy2> = try! dummy2FetchRequest().fetchRequest()
        
        // Different contexts for each operation.
        let saveContext = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        // Save the dummies in memory. Their NSManagedObject equivalents will
        // be constructed here.
        manager.rx.save(saveContext, dummies)
            
            // Perform a fetch to verify that the data have been inserted, but
            // not persisted.
            .flatMap({manager.rx.fetch(fetchContext1, fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({_ in XCTAssertEqual(mainContext.insertedObjects.count, dummyCount)})
            .doOnNext({_ in XCTAssertTrue(privateContext.insertedObjects.isEmpty)})
            .map(toVoid)
            
            // Persist the data.
            .flatMap({manager.rx.persistLocally()})
            
            // Fetch the data and verify that they have been persisted.
            .flatMap({manager.rx.fetch(fetchContext2, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
        let dummyCount = self.dummyCount
        let pureObjects = (0..<dummyCount).flatMap({_ in Dummy1()})
        let cdObjects = try! manager.constructUnsafely(context, pureObjects)
        let entityName = try! Dummy1.CDClass.entityName()
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let refetchContext = manager.disposableObjectContext()
        
        /// When
        // Save data without persisting to DB.
        manager.rx.save(saveContext, cdObjects)
            
            // Persist data to DB.
            .flatMap({_ in manager.rx.persistLocally()})
            
            // Refetch based on identifiable objects. We expect the returned
            // data to contain the same properties.
            .flatMap({manager.rx.refetch(refetchContext, entityName, cdObjects)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
        let dummyCount = self.dummyCount
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
        manager.rx.save(saveContext, cdObjects1)
            
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
            .flatMap({_ in manager.rx.delete(deleteContext, entityName, cdObjects2)})
            
            // Persist changes to DB.
            .flatMap({manager.rx.persistLocally()})
            
            // Fetch to verify that the DB is now empty.
            .flatMap({manager.rx.fetch(fetchContext2, fetchRq)})
            .flatMap({Observable.from($0)})
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
        // This does not work for in-memory store.
        if case .InMemory = self.storeType! {
            return
        }
        
        /// Setup
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let cdObjects = try! manager.constructUnsafely(context, pureObjects)
        let fetchRequest = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        let deleteRequest = try! dummy1FetchRequest().untypedFetchRequest()
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext1 = manager.disposableObjectContext()
        let deleteContext = manager.disposableObjectContext()
        let fetchContext2 = manager.disposableObjectContext()
        
        /// When
        manager.rx.save(saveContext, cdObjects)
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext1, fetchRequest)})
            .map({$0.map({$0.asPureObject()})})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            .flatMap({_ in manager.rx.delete(deleteContext, deleteRequest)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({_ in manager.rx.fetch(fetchContext2, fetchRequest)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
        let iterationCount = 100
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
                let sc2 = manager.disposableObjectContext()
                
                return Observable<[Dummy1.CDClass]>
                    .create({
                        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
                        let cdObjects = try! manager.constructUnsafely(sc1, pureObjects)
                        $0.onNext(cdObjects)
                        $0.onCompleted()
                        return Disposables.create()
                    })
                    .flatMap({manager.rx.save(sc2, $0)})
                    .map(toVoid)
                    .subscribeOn(qos: .background)
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
                let sc1 = manager.disposableObjectContext()
                let sc2 = manager.disposableObjectContext()
                
                return manager.rx.construct(sc1, objects)
                    
                    // Delete from memory, but do not persist yet.
                    .flatMap({manager.rx.delete(sc2, entityName, $0)})
            })

            // Persist the changes.
            .flatMap({manager.rx.persistLocally()})

            // Fetch to verify that the data have been deleted.
            .flatMap({manager.rx.fetch(fetchContext2, request).subscribeOn(qos: .background)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
    public func test_predicateForUpsertFetch_shouldWork() {
        /// Setup
        let times = 1000
        let context = manager.disposableObjectContext()
        let pureObjs = (0..<times).map({_ in Dummy1()})
        let objs = try! manager.constructUnsafely(context, pureObjs)
        
        /// When
        let predicate = manager.predicateForIdentifiableFetch(objs)
        
        /// Then
        let description = predicate.description
        let dComponents = description.components(separatedBy: " ")
        let dummyValues = objs.flatMap({$0.primaryValue()})
        XCTAssertEqual(dummyValues.count, times)
        XCTAssertEqual(dComponents.filter({$0 == "OR"}).count, times - 1)
        XCTAssertTrue(dummyValues.all(description.contains))
    }
}

public extension CoreDataManagerTest {
    public func test_saveConvertiblesToDB_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
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
        manager.rx.save(saveContext, convertibles)
            .doOnNext({XCTAssertTrue($0.all({$0.isSuccess()}))})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
        let dummyCount = self.dummyCount
        let pureObjects1 = (0..<dummyCount).map({_ in Dummy1()})
        
        let pureObjects2 = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            dummy.id = pureObjects1[i].id
            return dummy
        })
        
        let pureObjects3 = (0..<dummyCount).map({_ in Dummy1()})
        let pureObjects23 = [pureObjects2, pureObjects3].flatMap({$0})
        let cdObjects1 = try! manager.constructUnsafely(context, pureObjects1)
        let cdObjects23 = try! manager.constructUnsafely(context, pureObjects23)
        let fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        let entityName = fetchRq.entityName!
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let upsertContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()
        
        /// When
        manager.rx.save(saveContext, cdObjects1)
            .flatMap({_ in manager.rx.persistLocally()})
            
            // We expect the edited data to overwrite, while new data will
            // simply be inserted.
            .flatMap({_ in manager.rx.upsert(upsertContext, entityName, cdObjects23)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, pureObjects23.count)
        XCTAssertTrue(pureObjects23.all(nextElements.contains))
    }
}

public extension CoreDataManagerTest {
    public func test_fetchLimit_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let limit = dummyCount / 2
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let cdObjects = try! manager.constructUnsafely(context, pureObjects)
        
        let fetchRq = try! dummy1FetchRequest().cloneBuilder()
            .with(fetchLimit: limit)
            .build()
            .fetchRequest(Dummy1.self)
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()
        
        /// When
        manager.rx.save(saveContext, cdObjects)
            .flatMap({_ in manager.rx.persistLocally()})
            
            // We expect the number of results returned by this fetch to be
            // limited to the predefined fetchLimit.
            .flatMap({manager.rx.fetch(fetchContext, fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
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
