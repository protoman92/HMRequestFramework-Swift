//
//  CoreDataRootTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 10/8/17.
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

public class CoreDataRootTest: RootTest {
    public typealias Req = HMCDRequestProcessor.Req
    var dummyCount: Int!
    var manager: HMCDManager!
    var dbProcessor: HMCDRequestProcessor!
    
    override public func setUp() {
        super.setUp()
        dummyCount = 100
        manager = Singleton.coreDataManager(.background, .InMemory)
        dbProcessor = Singleton.dbProcessor(manager!)
    }
}

extension CoreDataRootTest {
    func dummy1FetchRequest() -> Req {
        return Req.builder()
            .with(poType: Dummy1.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
}

extension CoreDataRootTest {
    func dummy2FetchRequest() -> Req {
        return Req.builder()
            .with(cdType: CDDummy2.self)
            .with(operation: .fetch)
            .with(predicate: NSPredicate(value: true))
            .with(sortDescriptors: NSSortDescriptor(key: "id", ascending: true))
            .build()
    }
}
