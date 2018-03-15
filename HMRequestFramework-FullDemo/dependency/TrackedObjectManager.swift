//
//  TrackedObjectManager.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxSwift
import SwiftUtilities

public struct TrackedObjectManager {
    fileprivate let dbRequestManager: HMCDRequestProcessor
    fileprivate let dbUser: BehaviorSubject<Try<User>>
    fileprivate let disposeBag: DisposeBag
    
    public init(_ dbRequestManager: HMCDRequestProcessor) {
        self.dbRequestManager = dbRequestManager
        dbUser = BehaviorSubject(value: Try.failure(Exception("")))
        disposeBag = DisposeBag()
        initializeUserStream()
    }
    
    fileprivate func initializeUserStream() {
        dbRequestManager
            .streamDBEvents(User.self, .userInteractive, {
                Observable.just($0.cloneBuilder()
                    .add(descendingSortWithKey: User.updatedAtKey)
                    .build())
            })
            .flatMap({HMCDEvents.didLoadSections($0)})
            .map({$0.flatMap({$0.objects})})
            .map({$0.first.asTry(error: "No user found")})
            .logNextPrefix(">>>>>>>>>>>>>>>>>>>>>>>>")
            .observeOnConcurrent(qos: .userInteractive)
            .bind(to: dbUser)
            .disposed(by: disposeBag)
    }
    
    public func dbUserStream() -> Observable<Try<User>> {
        return dbUser.asObservable()
    }
}
