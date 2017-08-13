//
//  CoreDataObjectTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 11/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import XCTest
@testable import HMRequestFramework

public final class CoreDataObjectTest: CoreDataRootTest {
    public func test_updateCDObjectsWithDict_shouldWork() {
        /// Setup
        let manager = self.manager!
        let context = manager.disposableObjectContext()
        let dummyCount = self.dummyCount
        let pureObjects1 = (0..<dummyCount).map({_ in Dummy1()})
        let pureObjects2 = (0..<dummyCount).map({_ in Dummy1()})
        let cdObjects1 = try! manager.constructUnsafely(context, pureObjects1)
        let cdObjects2 = try! manager.constructUnsafely(context, pureObjects2)
        
        /// When
        cdObjects2.enumerated().forEach({
            try! $0.element.update(from: cdObjects1[$0.offset])
        })
        
        /// Then
        let reconverted2 = cdObjects2.map({$0.asPureObject()})
        XCTAssertTrue(pureObjects1.all(reconverted2.contains))
        XCTAssertFalse(pureObjects2.any(reconverted2.contains))
    }
}
