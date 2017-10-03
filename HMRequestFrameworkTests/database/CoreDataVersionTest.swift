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
    fileprivate var pureObjects1: [Dummy1]!
    fileprivate var editedPureObjects: [Dummy1]!
    fileprivate var serverPureObjects: [Dummy1]!
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
        pureObjects1 = (0..<dummyCount).map({_ in Dummy1()})
        
        // pureObjects2 have the same version while pureObjects3 differ.
        
        editedPureObjects = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            let previous = pureObjects1[i]
            dummy.id = previous.id
            dummy.version = previous.version
            return dummy
        })
        
        serverPureObjects = (0..<dummyCount).map({(i) -> Dummy1 in
            let dummy = Dummy1()
            let previous = pureObjects1[i]
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
        let serverPureObjects = self.serverPureObjects!
        let editedPureObjects = self.editedPureObjects!
        let editedCDObjects = try! manager.constructUnsafely(context, editedPureObjects)
        let serverCDObjects = try! manager.constructUnsafely(context, serverPureObjects)

        let updateRequests = editedCDObjects.enumerated().map({
            HMCDVersionUpdateRequest.builder()
                .with(edited: $0.element)
                .with(strategy: strategies[$0.offset])
                .build()
        })
        
        // Different contexts.
        let context1 = manager.disposableObjectContext()
        let context2 = manager.disposableObjectContext()
        let context3 = manager.disposableObjectContext()

        /// When
        // When we save data3, we are simulating the scenario whereby an edit
        // is happening when some other processes from another thread update
        // the DB to overwrite data.
        manager.rx.saveConvertibles(context1, serverCDObjects)
            .flatMap({_ in manager.rx.persistLocally()})

            // When we update the versioned objects, we apply random conflict
            // strategies to the Array.
            .flatMap({manager.rx.updateVersion(context2, entityName, updateRequests)})
            .doOnNext({XCTAssertEqual($0.filter({$0.isFailure()}).count, errorCount)})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({_ in manager.rx.fetch(context3, self.fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        var resultOverwriteCount = 0
        var otherCount = 0

        for element in nextElements {
            if editedPureObjects.contains(element) {
                resultOverwriteCount += 1
            } else if serverPureObjects.contains(element) {
                otherCount += 1
            }
        }

        XCTAssertEqual(nextElements.count, updateCount)
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
        let editedPureObjects = self.editedPureObjects!
        let serverPureObjects = self.serverPureObjects!
        let newPureObjects = (0..<dummyCount).map({_ in Dummy1()})
        let toBeSaved = [editedPureObjects, newPureObjects].flatMap({$0})
        let serverCDObjects = try! manager.constructUnsafely(context, serverPureObjects)
        let toBeSavedCDObjects = try! manager.constructUnsafely(context, toBeSaved)

        let updateRequests = toBeSavedCDObjects.map({
            HMCDVersionUpdateRequest.builder()
                .with(edited: $0)
                .with(strategy: .overwrite)
                .build()
        })

        let entityName = try! Dummy1.CDClass.entityName()
        
        // Different contexts.
        let saveContext = manager.disposableObjectContext()
        let versionContext = manager.disposableObjectContext()
        let fetchContext = manager.disposableObjectContext()

        /// When
        // Save data3 to simulate version conflicts.
        manager.rx.saveConvertibles(saveContext, serverCDObjects)
            .flatMap({_ in manager.rx.persistLocally()})

            // Since strategy is overwrite, we expect all updates to succeed.
            // Items that are not in the DB yet will be inserted.
            .flatMap({manager.rx.updateVersion(versionContext, entityName, updateRequests)})
            .doOnNext({XCTAssertTrue($0.all({$0.isSuccess()}))})
            .flatMap({_ in manager.rx.persistLocally()})
            .flatMap({manager.rx.fetch(fetchContext, self.fetchRq)})
            .map({$0.map({$0.asPureObject()})})
            .subscribeOnConcurrent(qos: .background)
            .flattenSequence()
            .doOnDispose(expect.fulfill)
            .subscribe(observer)
            .disposed(by: disposeBag)

        waitForExpectations(timeout: timeout, handler: nil)

        /// Then
        let nextElements = observer.nextElements()
        XCTAssertEqual(nextElements.count, toBeSaved.count)
        XCTAssertTrue(toBeSaved.all(nextElements.contains))
    }
}

public extension CoreDataVersionTest {
    func randomStrategies(_ times: Int) -> [VersionConflict.Strategy] {
        let strategies: [VersionConflict.Strategy] = [
            .error,
            .overwrite,
            .takePreferable
        ]
        
        let allCount = strategies.count
        return (0..<times).map({_ in strategies[Int.random(0, allCount)]})
    }
}
