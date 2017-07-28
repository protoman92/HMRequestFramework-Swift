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
    fileprivate let timeout: TimeInterval = 1000
    fileprivate let iterationCount = 1000
    fileprivate let dummyCount = 1000
    fileprivate let dummyTypeCount = 2
    fileprivate let generatorError = "Generator error!"
    fileprivate let processorError = "Processor error!"
    fileprivate let dummy: Try<Any> = Try.success(1)
    fileprivate var manager: ErrorCDManager!
    fileprivate var cdProcessor: HMCDRequestProcessor!
    fileprivate var dbProcessor: HMDatabaseRequestProcessor!
    fileprivate var disposeBag: DisposeBag!
    fileprivate var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        manager = Singleton.dummyCDManager()
        cdProcessor = HMCDRequestProcessor.builder().with(manager: manager).build()
        dbProcessor = HMDatabaseRequestProcessor(processor: cdProcessor)
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
        let cdDummy = try! dbProcessor.construct(dummy)
        
        /// Then
        XCTAssertEqual(dummy.id, cdDummy.id)
    }
    
    public func test_saveAndFetchBuildable_shouldWork() {
        /// Setup
        let dummyCount = 1000
        let manager = self.manager!
        let dummies = (0..<dummyCount).map({_ in Dummy3()})
        let fetchRq: NSFetchRequest<HMCDDummy3> = try! dummy3FetchRequest().fetchRequest()
        let observer = scheduler.createObserver(HMCDDummy3.self)
        let expect = expectation(description: ("Should have completed"))
        
        /// When
        manager.rx.saveToFile(dummies)
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
            .merge(manager.rx.saveToFile(d1), manager.rx.saveToFile(d2))
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
            .flatMap({manager.rx.saveToFile($0).subscribeOn(qos: .background)})
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
    
    public func test_insertRandomDummiesWithProcessor_shouldWork() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummyCount = self.dummyCount
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyPersistRgn(dummies)
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
    
    public func test_insertRandomDummiesWithError_shouldNotThrow() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyPersistRgn(dummies)
        let persistPs = dummyPersistRps()
        let expect = expectation(description: "Should have completed")
        let observer = scheduler.createObserver(Try<Void>.self)
        
        manager.saveDataToFileSuccess = {false}
        
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
        XCTAssertEqual(first.error!.localizedDescription, ErrorCDManager.saveDataToFileError)
    }
    
    public func test_fetchDummiesWithError_shouldNotThrow() {
        /// Setup
        let cdProcessor = self.cdProcessor!
        let context = manager.mainObjectContext()
        let dummies = randomDummies(Dummy1.self, context, dummyCount)
        let persistGn = dummyPersistRgn(dummies)
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
}

extension CoreDataRequestTest {
    func randomDummies<D>(_ dummyType: D.Type,
                          _ context: NSManagedObjectContext,
                          _ count: Int)
        -> [D] where D: DummyType
    {
        return (0..<count).flatMap({_ in try! D.init(context)})
    }
    
    func dummy1FetchRequest() -> HMCDRequestType {
        return HMCDRequest.builder()
            .with(convertible: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
    
    func dummy1FetchRgn() -> HMRequestGenerator<Any,HMCDRequestType> {
        return HMRequestGenerators.forceGenerateFn(generator: {_ in
            Observable.just(self.dummy1FetchRequest())
        })
    }
    
    func dummy1FetchRps() -> HMProtocolResultProcessor<Dummy1> {
        return {Observable.just(Try.success($0))}
    }
    
    func dummy2FetchRequest() -> HMCDRequestType {
        return HMCDRequest.builder()
            .with(convertible: Dummy2.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .build()
    }
    
    func dummy2FetchRgn() -> HMRequestGenerator<Any,HMCDRequestType> {
        return HMRequestGenerators.forceGenerateFn(generator: {_ in
            Observable.just(self.dummy2FetchRequest())
        })
    }
    
    func dummy2FetchRps() -> HMProtocolResultProcessor<Dummy2> {
        return {Observable.just(Try.success($0))}
    }
    
    func dummy3FetchRequest() -> HMCDRequestType {
        return HMCDRequest.builder()
            .with(convertible: HMCDDummy3.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
    
    func dummyPersistRequest(_ data: [NSManagedObject]) -> HMCDRequestType {
        return HMCDRequest.builder()
            .with(operation: .persistData)
            .with(dataToSave: data)
            .build()
    }
    
    func dummyPersistRgn(_ data: [NSManagedObject]) -> HMRequestGenerator<Any,HMCDRequestType> {
        return HMRequestGenerators.forceGenerateFn(generator: {_ in
            Observable.just(self.dummyPersistRequest(data))
        })
    }
    
    func dummyPersistRps() -> HMResultProcessor<Void,Void> {
        return {_ in Observable.just(Try.success())}
    }
    
    func errorDBRgn() -> HMRequestGenerator<Any,HMCDRequestType> {
        return {_ in throw Exception(self.generatorError)}
    }
    
    func errorDBRps() -> HMResultProcessor<NSManagedObject,Any> {
        return {_ in throw Exception(self.processorError)}
    }
}
