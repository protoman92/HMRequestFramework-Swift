//
//  RootTest.swift
//  HMRequestFramework-FullDemoTests
//
//  Created by Hai Pham on 18/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMReactiveRedux
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
    public var dbWait: TimeInterval!
    
    override public func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        singleton = Singleton.create(.InMemory)
        scheduler = TestScheduler(initialClock: 0)
        timeout = 10
        dbWait = 0.1
    }
}

public extension RootTest {
    public func globalErrorStream() -> Observable<Error?> {
        let path = HMGeneralReduxAction.Error.Display.errorPath
        return singleton.reduxStore.stateValueStream(Error.self, path)
    }
}
