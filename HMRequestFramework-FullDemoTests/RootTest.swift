//
//  RootTest.swift
//  HMRequestFramework-FullDemoTests
//
//  Created by Hai Pham on 18/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import RxSwift
import RxTest
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework_FullDemo

public class RootTest: XCTestCase {
    public var disposeBag: DisposeBag!
    public var singleton: SingletonType!
    public var scheduler: TestScheduler!
    public var timeout: TimeInterval!
    
    override public func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        singleton = Singleton.create(.InMemory)
        scheduler = TestScheduler(initialClock: 0)
        timeout = 10
    }
}
