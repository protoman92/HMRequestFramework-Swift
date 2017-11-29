//
//  CoreDataRequestTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 8/9/17.
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

public class CoreDataRequestTest: CoreDataRootTest {
    let generatorError = "Generator error!"
    let processorError = "Processor error!"
    
    /// This test represents the upper layer (API user). We are trying to prove
    /// that this upper layer knows nothing about the specific database
    /// implementation (e.g. CoreData or Realm).
    ///
    /// All specific database references are restricted to request generators
    /// and result processors.
    public func test_databaseRequestProcessor_shouldNotLeakContext() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let generator = errorDBRgn()
        let processor = errorDBRps()
        let qos: DispatchQoS.QoSClass = .background

        /// When
        dbProcessor.process(dummy, generator, processor, qos)
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor, qos)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor, qos)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor, qos)})
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertEqual(first.error?.localizedDescription, generatorError)
    }
    
    public func test_insertAndDeleteRandomDummies_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount!
        
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let cdObjects = try! manager.constructUnsafely(context, pureObjects)
        let splitIndex = Int(dummyCount / 2)
        
        // We get some from pure objects and the rest from CoreData objects to
        // check that the delete request works correctly by splitting the
        // deleted data into the appropriate slices (based on their types).
        let deletedObjects: [HMCDObjectConvertibleType] = [
            pureObjects[0..<splitIndex].map({$0 as HMCDObjectConvertibleType}),
            cdObjects[splitIndex..<dummyCount].map({$0 as HMCDObjectConvertibleType})
        ].flatMap({$0})
        
        let deleteGn = dummyMemoryDeleteRgn(deletedObjects)
        let qos: DispatchQoS.QoSClass = .background

        /// When
        // Save the changes in the disposable context.
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})

            // Fetch to verify that data have been persisted.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            .map(Try.success)

            // Delete data from memory, but do not persist to DB yet.
            .flatMap({dbProcessor.processVoid($0, deleteGn, qos)})

            // Persist changes to DB.
            .flatMap({dbProcessor.persistToDB($0, qos)})

            // Fetch to verify that the data have been deleted.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_deletePureObjects_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let qos: DispatchQoS.QoSClass = .background
        
        /// When
        // Save the original objects to DB.
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})
            
            // Fetch to verify that data have been persisted.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            .map(Try.success)
            
            // Delete pure objects from DB and persist changes.
            .flatMap({_ in dbProcessor.deleteInMemory(Try.success(pureObjects), qos)})
            .flatMap({dbProcessor.persistToDB($0, qos)})
            
            // Fetch to verify that the data have been deleted.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_fetchAndDeleteWithProperties_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        
        var fetchedProps: [String : [CVarArg]] = [:]
        fetchedProps["id"] = pureObjects.flatMap({$0.id})
        fetchedProps["date"] = pureObjects.flatMap({$0.date.map({$0 as NSDate})})
        fetchedProps["float"] = pureObjects.flatMap({$0.float})
        fetchedProps["int64"] = pureObjects.flatMap({$0.int64})
        
        let qos: DispatchQoS.QoSClass = .background
        
        /// When
        // Save the pure objects to DB.
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})
            
            // Fetch with properties and confirm that they match randomObjects.
            .flatMap({dbProcessor.fetchWithProperties($0, Dummy1.self, fetchedProps, .and, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, pureObjects.count)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            
            // Delete with properties and confirm that the DB is empty.
            .map(Try.success)
            .flatMap({dbProcessor.deleteWithProperties($0, Dummy1.self, fetchedProps, .and, qos)})
            .flatMap({dbProcessor.persistToDB($0, qos)})
            
            // Fetch with properties again to check that all objects are gone.
            .flatMap({dbProcessor.fetchWithProperties($0, Dummy1.self, fetchedProps, .and, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_batchDelete_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        
        let qos: DispatchQoS.QoSClass = .background

        /// When
        // Save the changes in the disposable context.
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({XCTAssertTrue(pureObjects.all($0.contains))})
            .map(Try.success)

            // Delete data from DB. Make sure this is a SQLite store though.
            .flatMap({dbProcessor.deleteAllInMemory($0, Dummy1.self, qos)})
            .flatMap({dbProcessor.persistToDB($0, qos)})

            // Fetch to verify that the data have been deleted.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_upsertWithOverwriteStrategy_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let dbProcessor = self.dbProcessor!
        let context = manager.disposableObjectContext()
        let times1 = 1000
        let times2 = 2000
        let pureObjects1 = (0..<times1).map({_ in Dummy1()})
        let pureObjects2 = (0..<times2).map({_ in Dummy1()})

        // Since we are using overwrite, we expect the upsert to still succeed.
        let pureObjects3 = (0..<times1).map({(index) -> Dummy1 in
            let dummy = Dummy1()
            let previous = pureObjects1[index]
            dummy.id = previous.id
            dummy.version = (previous.version!.intValue + 1) as NSNumber
            return dummy
        })

        let pureObjects23 = [pureObjects2, pureObjects3].flatMap({$0})
        let cdObjects23 = try! manager.constructUnsafely(context, pureObjects23)
        let upsertGn = dummy1UpsertRgn(cdObjects23, .overwrite)
        let upsertPs = dummy1UpsertRps()
        
        let qos: DispatchQoS.QoSClass = .background

        /// When
        // Insert the first set of data.
        dbProcessor.saveToMemory(Try.success(pureObjects1), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})

            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertTrue(pureObjects1.all($0.contains))})
            .doOnNext({XCTAssertEqual($0.count, times1)})
            .cast(to: Any.self).map(Try.success)

            // Upsert the second set of data. This set of data contains some
            // data with the same ids as the first set of data.
            .flatMap({dbProcessor.process($0, upsertGn, upsertPs, qos)})

            // Persist changes to DB.
            .flatMap({dbProcessor.persistToDB($0, qos)})

            // Fetch all data to check that the upsert was successful.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, pureObjects23.count)
        XCTAssertTrue(pureObjects23.all(nextElements.contains))
        XCTAssertFalse(pureObjects1.any(nextElements.contains))
    }
    
    public func test_upsertVersionableWithErrorStrategy_shouldNotOverwrite() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let dbProcessor = self.dbProcessor!
        let context = manager.disposableObjectContext()
        let times = 1000
        let pureObjects1 = (0..<times).map({_ in Dummy1()})

        // Since we are using error, we expect the upsert to fail.
        let pureObjects2 = (0..<times).map({(index) -> Dummy1 in
            let dummy = Dummy1()
            let previous = pureObjects1[index]
            dummy.id = previous.id
            dummy.version = (previous.version!.intValue + 1) as NSNumber
            return dummy
        })

        let cdObjects2 = try! manager.constructUnsafely(context, pureObjects2)
        let upsertGn = dummy1UpsertRgn(cdObjects2, .error)
        let upsertPs = dummy1UpsertRps()

        let qos: DispatchQoS.QoSClass = .background
        
        /// When
        // Insert the first set of data.
        dbProcessor.saveToMemory(Try.success(pureObjects1), qos)
            .map({$0.map({$0 as Any})})

            // Persist changes to DB.
            .flatMap({dbProcessor.persistToDB($0, qos)})
            .map({$0.map({$0 as Any})})

            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertTrue(pureObjects1.all($0.contains))})
            .doOnNext({XCTAssertEqual($0.count, times)})
            .cast(to: Any.self).map(Try.success)

            // Upsert the second set of data.
            .flatMap({dbProcessor.process($0, upsertGn, upsertPs, qos)})
            .map({$0.map({$0 as Any})})

            // Persist changes to DB.
            .flatMap({dbProcessor.persistToDB($0, qos)})
            .map({$0.map({$0 as Any})})

            // Fetch all data to check that the upsert failed.
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()

        // Only the old data exists in the DB. The updated versionables are not
        // persisted due to error conflict strategy.
        XCTAssertEqual(nextElements.count, times)
        XCTAssertTrue(pureObjects1.all(nextElements.contains))
        XCTAssertFalse(pureObjects2.any(nextElements.contains))
    }
    
    public func test_insertConvertibleData_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let qos: DispatchQoS.QoSClass = .background

        /// When
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.persistToDB($0, qos)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
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
    
    public func test_resetDBStack_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let dbProcessor = self.dbProcessor!
        let dummyCount = self.dummyCount!
        let pureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let qos: DispatchQoS.QoSClass = .background
        
        /// When
        dbProcessor.saveToMemory(Try.success(pureObjects), qos)
            .flatMap({dbProcessor.persistToDB($0, qos)})
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .map(Try.success)
            .flatMap({dbProcessor.resetStack($0, qos)})
            .flatMap({dbProcessor.fetchAllDataFromDB($0, Dummy1.self, qos)})
            .map({try $0.getOrThrow()})
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_cdNonTypedRequestObject_shouldThrowErrorsIfNecessary() {
        var currentCheck = 0
        let processor = self.dbProcessor!
        
        let checkError: (Req, Bool) -> Req = {
            currentCheck += 1
            print("Checking request \(currentCheck)")
            
            let request = $0
            
            do {
                _ = try processor.execute(request)
                    .subscribeOnConcurrent(qos: .background)
                    .toBlocking()
                    .first()
            } catch let e {
                print(e)
                XCTAssertTrue($1)
            }
            
            return request
        }
        
        /// 1
        let request1 = checkError(Req.builder().build(), true)
        
        /// 2
        let request2 = checkError(request1.cloneBuilder()
            .with(entityName: "E1")
            .build(), true)
        
        /// 3
        let request3 = checkError(request2.cloneBuilder()
            .with(operation: .persistLocally)
            .build(), true)
        
        /// End
        _ = request3
    }
}

extension CoreDataRequestTest {
    func dummy1UpsertRequest(_ data: [Dummy1.CDClass],
                             _ strategy: VersionConflict.Strategy) -> Req {
        return Req.builder()
            .with(operation: .upsert)
            .with(poType: Dummy1.self)
            .with(upsertedData: data)
            .with(vcStrategy: strategy)
            .build()
    }
    
    func dummy1UpsertRgn(_ data: [Dummy1.CDClass],
                         _ strategy: VersionConflict.Strategy)
        -> HMRequestGenerator<Any,Req>
    {
        let request = dummy1UpsertRequest(data, strategy)
        return HMRequestGenerators.forceGn(request, Any.self)
    }
    
    func dummy1UpsertRps() -> HMResultProcessor<HMCDResult,Void> {
        return {Observable.just($0).map(toVoid).map(Try.success)}
    }

    func dummyMemoryDeleteRequest(_ data: [HMCDObjectConvertibleType]) -> Req {
        return Req.builder()
            .with(operation: .deleteData)
            .with(deletedData: data)
            .build()
    }

    func dummyMemoryDeleteRgn(_ data: [HMCDObjectConvertibleType]) -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGn(dummyMemoryDeleteRequest(data))
    }
}

extension CoreDataRequestTest {
    func errorDBRgn() -> HMRequestGenerator<Any,Req> {
        return {_ in throw Exception(self.generatorError)}
    }

    func errorDBRps() -> HMResultProcessor<NSManagedObject,Any> {
        return {_ in throw Exception(self.processorError)}
    }
}
