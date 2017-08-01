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
    fileprivate let iterationCount = 10
    fileprivate let dummyCount = 10
    fileprivate let dummyTypeCount = 2
    fileprivate let generatorError = "Generator error!"
    fileprivate let processorError = "Processor error!"
    fileprivate let dummy: Try<Any> = Try.success(1)
    fileprivate var manager: ErrorCDManager!
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
            .flatMap({dbProcessor.process($0, generator, processor)})
            .flatMap({dbProcessor.process($0, generator, processor)})
            .flatMap({dbProcessor.process($0, generator, processor)})
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
        let dummyCount = 1000
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
        manager.rx.saveInMemory(dummies)
            .flatMap({manager.rx.fetch(fetchRq).toArray()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .doOnNext({_ in XCTAssertEqual(mainContext.insertedObjects.count, dummyCount)})
            .doOnNext({_ in XCTAssertTrue(privateContext.insertedObjects.isEmpty)})
            .map(toVoid)
            .flatMap({manager.rx.persistAllChangesToFile()})
            .flatMap({manager.rx.fetch(fetchRq)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, dummyCount)
    }
    
    public func test_insertRandomDummies_shouldWork() {
        /// Setup
        let dummyCount = 1000
        let manager = self.manager!
        let context = manager.mainObjectContext()
        let d1 = {self.randomDummies(Dummy1.self, context, dummyCount)}
        let d2 = {self.randomDummies(Dummy2.self, context, dummyCount)}
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        
        Observable
            .merge(manager.rx.saveInMemory(d1), manager.rx.saveInMemory(d2))
            .cast(to: Any.self)
            .subscribeOn(qos: .background)
            .observeOn(MainScheduler.instance)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let request1: NSFetchRequest<Dummy1> = try! dummy1FetchRequest().fetchRequest()
        let request2: NSFetchRequest<Dummy2> = try! dummy2FetchRequest().fetchRequest()
        let inserted1 = try! manager.blockingFetch(request1)
        let inserted2 = try! manager.blockingFetch(request2)
        let totalCount = inserted1.count + inserted2.count
        XCTAssertEqual(totalCount, dummyTypeCount * dummyCount)
    }
    
    public func test_insertManyRandomDummies_shouldWork() {
        /// Setup
        let manager = self.manager!
        let context = manager.mainObjectContext()
        let iterationCount = self.iterationCount
        let dummyCount = self.dummyCount
        let request: NSFetchRequest<Dummy1> = try! dummy1FetchRequest().fetchRequest()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Dummy1.self)
        
        /// When
        Observable.from(0..<iterationCount)
            .map({_ in self.randomDummies(Dummy1.self, context, dummyCount)})
            .flatMap({manager.rx.saveInMemory($0).subscribeOn(qos: .background)})
            .reduce((), accumulator: {_ in ()})
            .flatMap({manager.rx.fetch(request).subscribeOn(qos: .background)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let elements = observer.nextElements()
        XCTAssertEqual(elements.count, iterationCount * dummyCount)
    }
    
    public func test_insertAndDeleteRandomDummies_shouldWork() {
        /// Setup
        let dummyCount = 1000
        let manager = self.manager!
        let context = manager.mainObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let fetchRq: NSFetchRequest<Dummy1> = try! dummy1FetchRequest().fetchRequest()
        let observer = scheduler.createObserver(Any.self)
        let expect = expectation(description: "Should have completed")
        
        manager.rx.saveInMemory(dummies)
            .flatMap({_ in manager.rx.persistAllChangesToFile()})
            .flatMap({_ in manager.rx.fetch(fetchRq).toArray()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .flatMap({_ in manager.rx.deleteFromMemory(dummies)})
            .flatMap({_ in manager.rx.persistAllChangesToFile()})
            .flatMap({_ in manager.rx.fetch(fetchRq)})
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
    
    public func test_insertRandomDummiesWithProcessor_shouldWork() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummyCount = self.dummyCount
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyMemoryPersistRgn(dummies)
        let persistPs = dummyPersistRps()
        let fetchGn = dummy1FetchRgn()
        let fetchPs = dummy1FetchRps()
        let observer = scheduler.createObserver(Try<Dummy1Type>.self)
        let expect = expectation(description: "Should have completed")
        
        /// When
        cdProcessor.process(dummy, persistGn, persistPs)
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        nextElements.forEach({XCTAssertTrue($0.isSuccess)})
        XCTAssertEqual(nextElements.count, dummyCount)
    }
    
    public func test_insertAndDeleteRandomDummiesWithProcessor_shouldWork() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummyCount = self.dummyCount
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyMemoryPersistRgn(dummies)
        let persistPs = dummyPersistRps()
        let deleteGn = dummyMemoryDeleteRgn(dummies)
        let deletePs = dummyMemoryDeleteRps()
        let fetchGn = dummy1FetchRgn()
        let fetchPs = dummy1FetchRps()
        let observer = scheduler.createObserver(Try<Dummy1Type>.self)
        let expect = expectation(description: "Should have completed")
        
        /// When
        cdProcessor.process(dummy, persistGn, persistPs)
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs).toArray()})
            .doOnNext({XCTAssertEqual($0.count, dummyCount)})
            .map({$0 as Any}).map(Try.success)
            .flatMap({cdProcessor.process($0, deleteGn, deletePs)})
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 0)
    }
    
    public func test_insertRandomDummiesWithError_shouldNotThrow() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyMemoryPersistRgn(dummies)
        let persistPs = dummyPersistRps()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Void>.self)
        
        manager.saveInMemorySuccess = {false}
        
        /// When
        cdProcessor.process(dummy, persistGn, persistPs)
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertEqual(first.error!.localizedDescription, ErrorCDManager.saveInMemoryError)
    }
    
    public func test_fetchDummiesWithError_shouldNotThrow() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyMemoryPersistRgn(dummies)
        let persistPs = dummyPersistRps()
        let fetchGn = dummy1FetchRgn()
        let fetchPs = dummy1FetchRps()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Dummy1Type>.self)
        
        manager.fetchSuccess = {false}
        
        /// When
        cdProcessor.process(dummy, persistGn, persistPs)
            .map({$0.map({$0 as Any})})
            .flatMap({cdProcessor.process($0, fetchGn, fetchPs)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, 1)
        
        let first = nextElements.first!
        XCTAssertEqual(first.error!.localizedDescription, ErrorCDManager.fetchError)
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
            .with(dataToSave: [try! Dummy1(context)])
            .build(), false)
        
        /// End
        _ = request4
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
        let manager = self.manager!
        let dbProcessor = self.dbProcessor!
        let context = manager.mainObjectContext()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Dummy1>.self)
        let times1 = 2
        let times2 = 2
        let data1 = (0..<times1).map({_ in try! Dummy1(context)})
        let data2 = (0..<times2).map({_ in try! Dummy1(context)})
        
        let data3 = (0..<times1).map({(index) -> Dummy1 in
            let dummy = try! Dummy1(context)
            dummy.id = data1[index].id
            return dummy
        })
        
        let data23 = [data2, data3].flatMap({$0})
        
        let saveRq1 = Req.builder()
            .with(operation: .persistToFile)
            .with(dataToSave: data1)
            .build()
        
        let generator1 = HMRequestGenerators.forceGenerateFn(saveRq1, Any.self)
        let processor1: HMEQResultProcessor<Void> = HMResultProcessors.eqProcessor()
        
        let upsertRq23 = Req.builder()
            .with(operation: .upsert)
            .with(dataToUpsert: data23)
            .with(representable: Dummy1.self)
            .build()
        
        let generator2 = HMRequestGenerators.forceGenerateFn(upsertRq23, Any.self)
        let processor2: HMEQResultProcessor<Void> = HMResultProcessors.eqProcessor()
        
        let fetchRqAll = Req.builder()
            .with(representable: Dummy1.self)
            .with(predicate: NSPredicate(value: true))
            .with(operation: .fetch)
            .build()
        
        let fetchRq: NSFetchRequest<Dummy1> = try! fetchRqAll.fetchRequest()
        let generator3 = HMRequestGenerators.forceGenerateFn(fetchRqAll, Any.self)
        let processor3: HMEQResultProcessor<Dummy1> = HMResultProcessors.eqProcessor()
        
        /// When
        dbProcessor.process(dummy, generator1, processor1)
            .doOnNext({_ in try! print(manager.blockingFetch(fetchRq))})
            .doOnNext({_ in print(">>>>>>>>>>>>>>>>>>>")})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator2, processor2)})
            .map({$0.map({$0 as Any})})
            .flatMap({dbProcessor.process($0, generator3, processor3)})
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
    func dummyMemoryPersistRequest(_ data: [NSManagedObject]) -> Req {
        return Req.builder()
            .with(operation: .saveInMemory)
            .with(dataToSave: data)
            .build()
    }
    
    func dummyMemoryPersistRgn(_ data: [NSManagedObject]) -> HMRequestGenerator<Any,Req> {
        return HMRequestGenerators.forceGenerateFn(dummyMemoryPersistRequest(data))
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
