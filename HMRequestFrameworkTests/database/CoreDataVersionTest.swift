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
    fileprivate var ignoreCount: Int!
    fileprivate var fetchRq: NSFetchRequest<Dummy1.CDClass>!
    fileprivate var entityName: String!
    fileprivate var updateCount = 100
    
    override public func setUp() {
        super.setUp()
        let dummyCount = updateCount
        strategies = randomStrategies(dummyCount)
        errorCount = strategies.filter({$0 == .error}).count
        ignoreCount = strategies.filter({$0 == .ignore}).count
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
            dummy.id = poData1[i].id
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
        let ignoreCount = self.ignoreCount!
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        let context3 = manager.disposableObjectContext()
        let data1 = try! manager.constructUnsafely(context1, poData1)
        let data2 = try! manager.constructUnsafely(context2, poData2)
        let data3 = try! manager.constructUnsafely(context3, poData3)
        
        /// When
        // When we save data3, we are simulating the scenario whereby an edit
        // is happening when some other processes from another thread update
        // the DB to overwrite data.
        manager.rx.save(context3)
            .flatMap(manager.rx.persistLocally)
            
            // When we update the versioned objects, we apply random conflict
            // strategies to the Array.
            .flatMap({manager.rx.updateVersion(entityName, data2, {strategies[$0.0]})})
            .doOnNext({XCTAssertEqual($0.filter({$0.isFailure}).count, errorCount)})
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
        var resultErrorCount = 0
        var resultIgnoreCount = 0
        
        for element in nextElements {
            if poData3.contains(element) {
                resultErrorCount += 1
            } else {
                resultIgnoreCount += 1
            }
        }
        
        XCTAssertEqual(resultErrorCount, errorCount)
        XCTAssertEqual(resultIgnoreCount, ignoreCount)
    }
}

public extension CoreDataVersionTest {
    func randomStrategies(_ times: Int) -> [VersionConflict.Strategy] {
        let strategies = [VersionConflict.Strategy.error, .ignore]
        let allCount = strategies.count
        return (0..<times).map({_ in strategies[Int.random(0, allCount)]})
    }
}
