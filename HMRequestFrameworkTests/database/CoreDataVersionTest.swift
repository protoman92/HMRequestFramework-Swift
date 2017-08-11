//
//  CoreDataVersionTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 8/10/17.
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

public final class CoreDataVersionTest: CoreDataRootTest {
    fileprivate var poData1: [Dummy1]!
    fileprivate var poData2: [Dummy1]!
    fileprivate var poData3: [Dummy1]!
    fileprivate var strategies: [VersionConflict.Strategy]!
    fileprivate var errorCount: Int!
    fileprivate var overwriteCount: Int!
    fileprivate var takePreferableCount: Int!
    fileprivate var fetchRq: NSFetchRequest<Dummy1.CDClass>!
    fileprivate var entityName: String!
    fileprivate var updateCount = 1000
    
    override public func setUp() {
        super.setUp()
        let dummyCount = updateCount
        strategies = randomStrategies(dummyCount)
        errorCount = strategies.filter({$0 == .error}).count
        overwriteCount = strategies.filter({$0 == .overwrite}).count
        takePreferableCount = strategies.filter({$0 == .takePreferable}).count
        poData1 = (0..<dummyCount).map({_ in Dummy1()})
        
        // poData2 have the same version while poData3 differ.
        
        poData2 = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            let previous = poData1[i]
            dummy.id = previous.id
            dummy.version = previous.version
            return dummy
        })
        
        poData3 = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            let previous = poData1[i]
            dummy.id = previous.id
            dummy.version = (previous.version!.intValue + 1) as NSNumber
            return dummy
        })
        
        fetchRq = try! dummy1FetchRequest().fetchRequest(Dummy1.self)
        entityName = try! Dummy1.CDClass.entityName()
    }
    
    public func test_versionControl_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let entityName = self.entityName!
        let strategies = self.strategies!
        let errorCount = self.errorCount!
        let overwriteCount = self.overwriteCount!
        let takePreferableCount = self.takePreferableCount!
        let context = manager.disposableObjectContext()
        let data2 = try! manager.constructUnsafely(context, poData2)
        let data3 = try! manager.constructUnsafely(context, poData3)
        
        let requests2 = data2.enumerated().map({
            HMVersionUpdateRequest<Dummy1.CDClass>.builder()
                .with(edited: $0.element)
                .with(strategy: strategies[$0.offset])
                .build()
        })
        
        /// When
        // When we save data3, we are simulating the scenario whereby an edit
        // is happening when some other processes from another thread update
        // the DB to overwrite data.
        manager.rx.save(data3)
            .flatMap({_ in manager.rx.persistLocally()})
            
            // When we update the versioned objects, we apply random conflict
            // strategies to the Array.
            .flatMap({manager.rx.updateVersion(entityName, requests2)})
            .doOnNext({XCTAssertEqual($0.filter({$0.isFailure()}).count, errorCount)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({_ in manager.rx.fetch(self.fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        var resultOverwriteCount = 0
        var otherCount = 0
        
        for element in nextElements {
            if poData2.contains(element) {
                resultOverwriteCount += 1
            } else if poData3.contains(element) {
                otherCount += 1
            }
        }
        
        XCTAssertEqual(resultOverwriteCount, overwriteCount)
        XCTAssertEqual(otherCount, errorCount + takePreferableCount)
    }
    
    public func test_versionControlWithNonExistingItem_shouldWork() {
        /// Setup
        let observer = scheduler.createObserver(Dummy1.self)
        let expect = expectation(description: "Should have completed")
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.updateCount
        let poData2 = self.poData2!
        let poData3 = self.poData3!
        let poData4 = (0..<dummyCount).map({_ in Dummy1()})
        let poData24 = [poData2, poData4].flatMap({$0})
        let data3 = try! manager.constructUnsafely(context, poData3)
        let data24 = try! manager.constructUnsafely(context, poData24)
        
        let requests24 = data24.map({
            HMVersionUpdateRequest<Dummy1.CDClass>.builder()
                .with(edited: $0)
                .with(strategy: .overwrite)
                .build()
        })
        
        let entityName = try! Dummy1.CDClass.entityName()
        
        /// When
        // Save data3 to simulate version conflicts.
        manager.rx.save(data3)
            .flatMap({_ in manager.rx.persistLocally()})
            
            // Since strategy is overwrite, we expect all updates to succeed.
            // Items that are not in the DB yet will be inserted.
            .flatMap({manager.rx.updateVersion(entityName, requests24)})
            .doOnNext({XCTAssertTrue($0.all(satisfying: {$0.isSuccess()}))})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(self.fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .flatMap({Observable.from($0)})
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        /// Then
        let nextElements = observer.nextElements()
        XCTAssertTrue(poData24.all(satisfying: nextElements.contains))
    }
}

public extension CoreDataVersionTest {
    func randomStrategies(_ times: Int) -> [VersionConflict.Strategy] {
        let strategies = [VersionConflict.Strategy.error,
                          .overwrite,
                          .takePreferable]
        
        let allCount = strategies.count
        return (0..<times).map({_ in strategies[Int.random(0, allCount)]})
    }
}
