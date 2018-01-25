//
//  UserTextCellVMTest.swift
//  HMRequestFramework-FullDemoTests
//
//  Created by Hai Pham on 25/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import RxSwift
import RxTest
import SwiftUtilities
import SwiftUtilitiesTests
import XCTest
@testable import HMRequestFramework_FullDemo

/// We can use this model mock to stub api calls to provide values/throw errors.
public final class MockUserTextCellModel: UserTextCellModelType {
    public let model: UserTextCellModelType
    public var mockUpdateUser: ((Try<User>) throws -> Void)?
    
    public var userInformation: UserInformation {
        return model.userInformation
    }
    
    public init(_ model: UserTextCellModelType) {
        self.model = model
    }
    
    public func dbUserStream() -> Observable<Try<User>> {
        return model.dbUserStream()
    }
    
    public func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>> {
        return mockUpdateUser
            .map({fn in Observable.just(Try({try fn(user)}))})
            .getOrElse(model.updateUserInDB(user))
    }
    
    public func userProperty(_ user: User) -> String? {
        return model.userProperty(user)
    }
    
    public func updateUserProperty(_ user: User, _ text: String) -> User {
        return model.updateUserProperty(user, text)
    }
}

public final class UserTextCellVMTest: RootTest {
    public func mockNameModel() -> MockUserTextCellModel {
        let model = UserNameTextCellModel(singleton!)
        return MockUserTextCellModel(model)
    }
    
    public func mockAgeModel() -> MockUserTextCellModel {
        let model = UserAgeTextCellModel(singleton!)
        return MockUserTextCellModel(model)
    }
}

public extension UserTextCellVMTest {
    public func test_updateUserError_shouldUpdateGlobalState(_ model: MockUserTextCellModel) {
        /// Setup
        let errorObs = scheduler.createObserver(Error?.self)
        let vm = UserTextCellViewModel(singleton!, model)
        globalErrorStream().bind(to: errorObs).disposed(by: disposeBag)
        
        let error = "Failed to update user!"
        model.mockUpdateUser = {_ in throw Exception(error)}
        
        vm.setupBindings()
        
        /// When
        vm.textInputTrigger().onNext("TestInput!!")
        waitOnMainThread(dbWait!)
        
        /// Then
        let errorElements = errorObs.nextElements()
        XCTAssertEqual(errorElements.last??.localizedDescription, error)
    }
    
    public func test_updateUserNameError_shouldUpdateGlobalState() {
        let model = mockNameModel()
        test_updateUserError_shouldUpdateGlobalState(model)
    }
    
    public func test_updateUserAgeError_shouldUpdateGlobalState() {
        let model = mockAgeModel()
        test_updateUserError_shouldUpdateGlobalState(model)
    }
}
