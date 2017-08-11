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

public final class CoreDataRequestTest: CoreDataRootTest {
    public typealias Req = HMCDRequestProcessor.Req
    let generatorError = "Generator error!"
    let processorError = "Processor error!"
    var rqMiddlewareManager: HMMiddlewareManager<Req>!
    var cdProcessor: HMCDRequestProcessor!
    var dbProcessor: DBRequestProcessor!
    
    override public func setUp() {
        super.setUp()
        rqMiddlewareManager = HMMiddlewareManager<Req>.builder().build()
        
        cdProcessor = HMCDRequestProcessor.builder()
            .with(manager: manager)
            .with(rqMiddlewareManager: rqMiddlewareManager)
            .build()
        
        dbProcessor = DBRequestProcessor(processor: cdProcessor)
    }
    
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
        let dbProcessor = self.dbProcessor!.processor
        let generator = errorDBRgn()
        let processor = errorDBRps()
        
        /// When
        dbProcessor.process(dummy, generator, processor)
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertTrue(first.isFailure)
        XCTAssertEqual(first.error!.localizedDescription, generatorError)
    }
    
    public func test_insertAndDeleteRandomDummiesWithProcessor_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Try<Any>.self)
        let expect = expectation(description: "Should have completed")
        let cdProcessor = self.cdProcessor!
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let poDummies = (0..<dummyCount).map({_ in Dummy1()})
        let dummies = try! manager.constructUnsafely(context, poDummies)
        let saveContextGn = dummySaveContextRgn(context)
        let saveContextPs = dummyPersistRps()
        let persistGn = dummyPersistRgn()
        let persistPs = dummyPersistRps()
        let deleteGn = dummyMemoryDeleteRgn(dummies)
        let deletePs = dummyMemoryDeleteRps()
        let fetchGn = dummy1FetchRgn()
        let fetchPs = dummy1FetchRps()

        /// When
        // Save the changes in the disposable context.
        cdProcessor.process(dummy, saveContextGn, saveContextPs)
            .map({$0.map({$0 as Any})})

            // Persist changes to DB.
            .flatMap({cdProcessor.process($0, persistGn, persistPs)})
            .map({$0.map({$0 as Any})})

            // Fetch to verify that data have been persisted.
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .map({$0 as Any}).map(Try.success)

            // Delete data from memory, but do not persist to DB yet.
            .flatMap({cdProcessor.process($0, deleteGn, deletePs)})
            .map({$0.map({$0 as Any})})

            // Persist changes to DB.
            .flatMap({cdProcessor.process($0, persistGn, persistPs)})
            .map({$0.map({$0 as Any})})

            // Fetch to verify that the data have been deleted.
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .map({try $0.getOrThrow()})
            .flatMap({Observable.from($0)})
            .map({$0.map({$0 as Any})})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_coreDataUpsert_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Try<Dummy1>.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let dbProcessor = self.dbProcessor!.processor

        // We need 2 contexts here because we will perform 2 operations:
        // persist data1 to DB, and upsert data23. Under no circumstances
        // should the operations share a disposable context.
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        let times1 = 1000
        let times2 = 2000
        let poData1 = (0..<times1).map({_ in Dummy1()})
        let poData2 = (0..<times2).map({_ in Dummy1()})

        let poData3 = (0..<times1).map({(index) -> Dummy1 in
            let dummy = Dummy1()
            dummy.id = poData1[index].id
            return dummy
        })

        let poData23 = [poData2, poData3].flatMap({$0})
        _ = try! manager.constructUnsafely(context1, poData1)
        _ = try! manager.constructUnsafely(context2, poData23)

        let saveRq = Req.builder()
            .with(operation: .saveContext)
            .with(saveContext: context1)
            .build()

        let saveGn = HMRequestGenerators.forceGenerateFn(saveRq, Any.self)
        let savePs = HMResultProcessors.eqProcessor(Void.self)
        let persistGn = dummyPersistRgn()
        let persistPs = dummyPersistRps()

        let upsertRq = Req.builder()
            .with(operation: .upsert)
            .with(saveContext: context2)
            .with(poType: Dummy1.self)
            .build()

        let upsertGn = HMRequestGenerators.forceGenerateFn(upsertRq, Any.self)
        let upsertPs: HMEQResultProcessor<Void> = HMResultProcessors.eqProcessor()

        let fetchRqAll = Req.builder()
            .with(poType: Dummy1.self)
            .with(predicate: NSPredicate(value: true))
            .with(operation: .fetch)
            .build()

        let fetchGn = HMRequestGenerators.forceGenerateFn(fetchRqAll, Any.self)

        /// When
        // Insert the first set of data.
        dbProcessor.process(dummy, saveGn, savePs)
            .map({$0.map({$0 as Any})})
            .doOnNext({_ in
                print(try! manager.blockingFetch(fetchRqAll.fetchRequest(Dummy1.self)).map({$0.asPureObject()}))
            })
            
            // Persist changes to DB.
            .flatMap({dbProcessor.process($0, persistGn, persistPs)})
            .map({$0.map({$0 as Any})})
            
            .flatMap({dbProcessor.process($0, fetchGn, Dummy1.self)})
            .logNext()
            .doOnNext({XCTAssertEqual($0.value?.count, times1)})
            .map({$0.map({$0 as Any})})

            // Upsert the second set of data. This set of data contains some
            // data with the same ids as the first set of data.
            .flatMap({dbProcessor.process($0, upsertGn, upsertPs)})
            .map({$0.map({$0 as Any})})
            
            // Persist changes to DB.
            .flatMap({dbProcessor.process($0, persistGn, persistPs)})
            .map({$0.map({$0 as Any})})

            // Fetch all data to check that the upsert was successful.
            .flatMap({dbProcessor.process($0, fetchGn, Dummy1.self)})
            .map({try $0.getOrThrow()})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        let nextDummies = nextElements.flatMap({$0.value})
        XCTAssertEqual(nextElements.count, poData23.count)
        XCTAssertTrue(poData23.all(satisfying: nextDummies.contains))
        XCTAssertFalse(poData1.any(satisfying: nextDummies.contains))
    }
    
    public func test_cdNonTypedRequestObject_shouldThrowErrorsIfNecessary() {
        var currentCheck = 0
        let context = manager.mainObjectContext()
        let processor = cdProcessor!
        
        let checkError: (Req, Bool) -> Req = {
            currentCheck += 1
            print("Checking request \(currentCheck)")
            
            let request = $0.0
            
            do {
                _ = try processor.execute(request).toBlocking().first()
            } catch let e {
                print(e)
                XCTAssertTrue($0.1)
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
            .with(operation: .persistToFile)
            .build(), true)
        
        /// 4
        let request4 = checkError(request3.cloneBuilder()
            .with(saveContext: context)
            .build(), false)
        
        /// End
        _ = request4
    }
}

extension CoreDataRequestTest {
    func dummy1FetchRgn() -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummy1FetchRequest())
    }
    
    func dummy1FetchRps() -> HMCDTypedResultProcessor<Dummy1> {
        return {Observable.just(Try.success($0.asPureObject()))}
    }
}

extension CoreDataRequestTest {
    func dummySaveContextRequest(_ context: NSManagedObjectContext) -> Req {
        return Req.builder()
            .with(operation: .saveContext)
            .with(saveContext: context)
            .build()
    }

    func dummySaveContextRgn(_ context: NSManagedObjectContext) -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummySaveContextRequest(context))
    }

    func dummySaveContextRps() -> HMEQResultProcessor<Void> {
        return HMResultProcessors.eqProcessor()
    }
}

extension CoreDataRequestTest {
    func dummyPersistRequest() -> Req {
        return Req.builder().with(operation: .persistToFile).build()
    }

    func dummyPersistRgn() -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummyPersistRequest())
    }

    func dummyPersistRps() -> HMEQResultProcessor<Void> {
        return HMResultProcessors.eqProcessor()
    }
}

extension CoreDataRequestTest {
    func dummyMemoryDeleteRequest(_ data: [NSManagedObject]) -> Req {
        return Req.builder()
            .with(operation: .delete)
            .with(deletedData: data)
            .build()
    }

    func dummyMemoryDeleteRgn(_ data: [NSManagedObject]) -> HMAnyRequestGenerator<Req> {
        return HMRequestGenerators.forceGenerateFn(dummyMemoryDeleteRequest(data))
    }

    func dummyMemoryDeleteRps() -> HMEQResultProcessor<Void> {
        return HMResultProcessors.eqProcessor()
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
