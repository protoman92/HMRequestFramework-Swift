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

public class CoreDataRootTest: XCTestCase {
    public typealias Req = HMCDRequestProcessor.Req
    let timeout: TimeInterval = 1000
    var dummyCount: Int!
    let dummy: Try<Any> = Try.success(1)
    var storeType: HMCDPersistentStoreSettings.StoreType!
    var manager: HMCDManager!
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    override public func setUp() {
        super.setUp()
        dummyCount = 1000
        storeType = .InMemory
        
        let fileManager = FileManager.default
        
        let url = HMCDPersistentStoreURL.builder()
            .with(fileManager: fileManager)
            .withDocumentDirectory()
            .withUserDomainMask()
            .with(fileName: "HMRequestFramework")
            .with(storeType: .SQLite)
            .build()
        
        print("Creating store at \(try! url.storeURL())")
        try? fileManager.removeItem(at: try! url.storeURL())
        
        let settings = [
            HMCDPersistentStoreSettings.builder()
                .with(storeType: storeType)
                .with(persistentStoreURL: url)
                .build()
        ]
        
        let constructor = HMCDConstructor.builder()
            .with(cdTypes: Dummy1.CDClass.self, Dummy2.CDClass.self)
            .with(settings: settings)
            .build()
        
        manager = try! HMCDManager(constructor: constructor)
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
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
