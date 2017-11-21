//
//  CoreDataSectionTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/11/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import XCTest
@testable import HMRequestFramework

public final class CoreDataSectionTest: XCTestCase {}

extension CoreDataSectionTest {
    public func test_mapSectionObjects_shouldWork<SC,SC2>(_ cls1: SC.Type, _ cls2: SC2.Type) where
        SC: HMCDSectionType, SC.V == String,
        SC2: HMCDSectionType, SC2.V == Int
    {
        /// Setup
        let objects = ["1", "2", "3"]
        let newObjects = objects.flatMap({Int($0)})
        let section = SC.init(indexTitle: nil, name: "", objects: objects)
        
        /// When
        let section2 = section.mapObjects({$0.flatMap({Int($0)})}, cls2)
        let section3 = section.mapObjects({_ -> [Int]? in nil}, cls2)
        
        /// Then
        XCTAssertEqual(section2.objects, newObjects)
        XCTAssertEqual(section3.objects, [])
        XCTAssertEqual(section3.numberOfObjects, 0)
    }
    
    public func test_mapReloadSectionObjects_shouldWork() {
        typealias Section = HMCDSection
        test_mapSectionObjects_shouldWork(Section<String>.self, Section<Int>.self)
    }
    
    public func test_mapAnimatableSectionObjects_shouldWork() {
        typealias Section = HMCDAnimatableSection
        test_mapSectionObjects_shouldWork(Section<String>.self, Section<Int>.self)
    }
}
