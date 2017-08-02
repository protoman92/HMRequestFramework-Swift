//
//  CoreDataRequestTest.swift
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

public final class CoreDataRequestTest: XCTestCase {
    public typealias Req = HMCDRequestProcessor.Req
    fileprivate let timeout: TimeInterval = 1000
    fileprivate let iterationCount = 100
    fileprivate let dummyCount = 100
    fileprivate let dummyTypeCount = 2
    fileprivate let generatorError = "Generator error!"
    fileprivate let processorError = "Processor error!"
    fileprivate let dummy: Try<Any> = Try.success(1)
    fileprivate var manager: HMCDManager!
    fileprivate var rqMiddlewareManager: HMMiddlewareManager<Req>!
    fileprivate var cdProcessor: HMCDRequestProcessor!
    fileprivate var dbProcessor: DatabaseRequestProcessor!
    fileprivate var disposeBag: DisposeBag!
    fileprivate var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        manager = Singleton.dummyCDManager()
        rqMiddlewareManager = HMMiddlewareManager<Req>.builder().build()
        
        cdProcessor = HMCDRequestProcessor.builder()
            .with(manager: manager)
            .with(rqMiddlewareManager: rqMiddlewareManager)
            .build()
        
        dbProcessor = DatabaseRequestProcessor(processor: cdProcessor)
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    /// This test represents the upper layer (API user). We are trying to prove
    /// that this upper layer knows nothing about the specific database
    /// implementation (e.g. CoreData or Realm).
    ///
    /// All specific database references are restricted to request generators
    /// and result processors.
    public func test_databaseRequestProcessor_shouldNotLeakContext() {
        /// Setup
        let dbProcessor = self.dbProcessor!
        let generator = errorDBRgn()
        let processor = errorDBRps()
        let observer = scheduler.createObserver(Try<Any>.self)
        
        /// When
        dbProcessor.process(dummy, generator, processor)
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .map({$0.map({$0 as Any})})
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertTrue(first.isFailure)
        XCTAssertEqual(first.error!.localizedDescription, generatorError)
    }
    
    public func test_constructBuildable_shouldWork() {
        /// Setup
        let dummy = Dummy3()
        
        /// When
        let cdDummy = try! manager.construct(dummy)
        let reconstructed = cdDummy.asPureObject()
        
        /// Then
        XCTAssertEqual(dummy, reconstructed)
    }
    
    public func test_saveAndFetchBuildable_shouldWork() {
        /// Setup
        let dummyCount = self.dummyCount
        let manager = self.manager!
        let mainContext = manager.mainContext
        let privateContext = manager.privateContext
        let dummies = (0..<dummyCount).map({_ in Dummy3()})
        let fetchRq: NSFetchRequest<HMCDDummy3> = try! dummy3FetchRequest().fetchRequest()
        let observer = scheduler.createObserver(HMCDDummy3.self)
        let expect = expectation(description: ("Should have completed"))
        XCTAssertTrue(mainContext.insertedObjects.isEmpty)
        XCTAssertTrue(privateContext.insertedObjects.isEmpty)
        
        /// When
        // Save the dummies in memory. Their NSManagedObject equivalents will
        // be constructed here.
        manager.rx.saveInMemory(dummies)
            
            // Perform a fetch to verify that the data have been inserted, but
            // not persisted.
            .flatMap({manager.rx.fetch(fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({_ in XCTAssertEqual(mainContext.insertedObjects.count, dummyCount)})
            .doOnNext({_ in XCTAssertTrue(privateContext.insertedObjects.isEmpty)})
            .map(toVoid)
            
            // Persist the data.
            .flatMap(manager.rx.persistAllChangesToFile)
            
            // Fetch the data and verify that they have been persisted.
            .flatMap({manager.rx.fetch(fetchRq)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
    }
    
    public func test_insertAndDeleteRandomDummies_shouldWork() {
        /// Setup
        let dummyCount = self.dummyCount
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let fetchRq: NSFetchRequest<Dummy1> = try! dummy1FetchRequest().fetchRequest()
        let entityName = try! Dummy1.entityName()
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        
        // The NSManagedObjects, once initilized, should have been inserted into
        // this context. When we save it, we propagate the changes one level
        // up to the main context.
        manager.rx.save(context)
            
            // Persist the data to DB.
            .flatMap(manager.rx.persistAllChangesToFile)
            
            // Fetch to verify that the data have been persisted.
            .flatMap({_ in manager.rx.fetch(fetchRq)})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            
            // Delete the data from memory without persisting the changes.
            .flatMap({_ in manager.rx.deleteFromMemory(entityName, dummies)})
            
            // Persist the changes.
            .flatMap(manager.rx.persistAllChangesToFile)
            
            // Fetch to verify that all data have been deleted.
            .flatMap({_ in manager.rx.fetch(fetchRq)})
            .flatMap({Observable.from($0)})
            .cast(to: Any.self)
            .subscribeOn(qos: .background)
            .observeOn(MainScheduler.instance)
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
        let manager = self.manager!
        let iterationCount = self.iterationCount
        let dummyCount = self.dummyCount
        let entityName = try! Dummy1.entityName()
        let request: NSFetchRequest<Dummy1> = try! dummy1FetchRequest().fetchRequest()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Dummy1.self)
        
        /// When
        Observable.from(0..<iterationCount)
            
            // For each iteration, create a bunch of dummies in a disposable
            // context and save them in memory. The main context should then
            // own the changes.
            .flatMap({(_) -> Observable<Void> in
                let context = manager.disposableObjectContext()
                let _ = self.randomDummies(Dummy1.self, context, dummyCount)
                return manager.rx.save(context).subscribeOn(qos: .background)
            })
            .reduce((), accumulator: {_ in ()})
            
            // Persist all changes to DB.
            .flatMap(manager.rx.persistAllChangesToFile)
            
            // Fetch to verify that the data have been persisted.
            .flatMap({manager.rx.fetch(request).subscribeOn(qos: .background)})
            .doOnNext({XCTAssertEqual($0.count, iterationCount * dummyCount)})
            
            // Delete from memory, but do not persist yet.
            .flatMap({manager.rx.deleteFromMemory(entityName, $0)})
            
            // Persist the changes.
            .flatMap(manager.rx.persistAllChangesToFile)
            
            // Fetch to verify that the data have been deleted.
            .flatMap({manager.rx.fetch(request).subscribeOn(qos: .background)})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, 0)
    }

    public func test_insertAndDeleteRandomDummiesWithProcessor_shouldWork() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let saveContextGn = dummySaveContextRgn(context)
        let saveContextPs = dummyPersistRps()
        let persistGn = dummyPersistRgn()
        let persistPs = dummyPersistRps()
        let deleteGn = dummyMemoryDeleteRgn(dummies)
        let deletePs = dummyMemoryDeleteRps()
        let fetchGn = dummy1FetchRgn()
        let fetchPs = dummy1FetchRps()
        let observer = scheduler.createObserver(Try<Dummy1Type>.self)
        let expect = expectation(description: "Should have completed")

        /// When
        // Save the changes in the disposable context.
        cdProcessor.process(dummy, saveContextGn, saveContextPs)
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, persistGn, persistPs)})
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .map({try $0.getOrThrow()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .map({$0 as Any}).map(Try.success)
            .flatMap({cdProcessor.process($0, deleteGn, deletePs)})
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .map({try $0.getOrThrow()})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_predicateForUpsertFetch_shouldWork() {
        /// Setup
        let times = 1000
        let context = manager.mainObjectContext()
        let objs = (0..<times).map({_ in try! Dummy1(context)})
        
        /// When
        let predicate = manager.predicateForUpsertableFetch(objs)
        
        /// Then
        let description = predicate.description
        let dComponents = description.components(separatedBy: " ")
        let dummyValues = objs.map({$0.primaryValue()})
        XCTAssertEqual(dComponents.filter({$0 == "OR"}).count, times - 1)
        XCTAssertTrue(dummyValues.all(satisfying: description.contains))
    }
    
    public func test_coreDataUpsert_shouldWork() {
        /// Setup
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Dummy1>.self)
        let manager = self.manager!
        let dbProcessor = self.dbProcessor!
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        let times1 = 1000
        let times2 = 1000
        let data1 = (0..<times1).map({_ in try! Dummy1(context1)})
        let data2 = (0..<times2).map({_ in try! Dummy1(context2)})

        let data3 = (0..<times1).map({(index) -> Dummy1 in
            let dummy = try! Dummy1(context2)
            dummy.id = data1[index].id
            return dummy
        })

        let data23 = [data2, data3].flatMap({$0})

        let saveRq1 = Req.builder()
            .with(operation: .saveContext)
            .with(contextToSave: context1)
            .build()

        let generator1 = HMRequestGenerators.forceGenerateFn(saveRq1, Any.self)
        let processor1: HMEQResultProcessor<Void> = HMResultProcessors.eqProcessor()

        let upsertRq23 = Req.builder()
            .with(operation: .upsert)
            .with(contextToSave: context2)
            .with(representable: Dummy1.self)
            .build()

        let generator2 = HMRequestGenerators.forceGenerateFn(upsertRq23, Any.self)
        let processor2: HMEQResultProcessor<Void> = HMResultProcessors.eqProcessor()

        let fetchRqAll = Req.builder()
            .with(representable: Dummy1.self)
            .with(predicate: NSPredicate(value: true))
            .with(operation: .fetch)
            .build()

        let generator3 = HMRequestGenerators.forceGenerateFn(fetchRqAll, Any.self)
        let processor3: HMEQResultProcessor<Dummy1> = HMResultProcessors.eqProcessor()

        /// When
        // Insert the first set of data
        dbProcessor.process(dummy, generator1, processor1)
            .map({$0.map({$0 as Any})})
            
            // Upsert the second set of data
            .flatMap({dbProcessor.process($0, generator2, processor2)})
            .map({$0.map({$0 as Any})})
            
            // Fetch all data
            .flatMap({dbProcessor.process($0, generator3, processor3)})
            .map({try $0.getOrThrow()})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        let nextDummies = nextElements.flatMap({$0.value})
        XCTAssertEqual(nextElements.count, data23.count)

        XCTAssertTrue(data23.all(satisfying: {dummy1 in
            nextDummies.contains(where: {
                $0.id == dummy1.id &&
                $0.date == dummy1.date &&
                $0.int64 == dummy1.int64 &&
                $0.float == dummy1.float
            })
        }))
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
            .with(contextToSave: context)
            .build(), false)
        
        /// End
        _ = request4
    }
}

extension CoreDataRequestTest {
    func randomDummies<D>(_ dummyType: D.Type,
                          _ context: NSManagedObjectContext,
                          _ count: Int)
        -> [D] where D: DummyType
    {
        return (0..<count).flatMap({_ in try! D.init(context)})
    }
}

extension CoreDataRequestTest {
    func dummy1FetchRequest() -> Req {
        return Req.builder()
            .with(representable: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
    
    func dummy1FetchRgn() -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummy1FetchRequest())
    }
    
    func dummy1FetchRps() -> HMProtocolResultProcessor<Dummy1> {
        return {Observable.just(Try.success($0))}
    }
}

extension CoreDataRequestTest {
    func dummy2FetchRequest() -> Req {
        return Req.builder()
            .with(representable: Dummy2.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .build()
    }
    
    func dummy2FetchRgn() -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummy2FetchRequest())
    }
    
    func dummy2FetchRps() -> HMProtocolResultProcessor<Dummy2> {
        return {Observable.just(Try.success($0))}
    }
}

extension CoreDataRequestTest {
    func dummy3FetchRequest() -> Req {
        return Req.builder()
            .with(representable: HMCDDummy3.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
}

extension CoreDataRequestTest {
    func dummySaveContextRequest(_ context: NSManagedObjectContext) -> Req {
        return Req.builder()
            .with(operation: .saveContext)
            .with(contextToSave: context)
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
            .with(dataToDelete: data)
            .build()
    }
    
    func dummyMemoryDeleteRgn(_ data: [NSManagedObject]) -> HMRequestGenerator<Any,Req> {
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
