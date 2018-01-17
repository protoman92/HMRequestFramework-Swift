//
//  UserTextCell.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities
import UIKit

public final class UserTextCell: UITableViewCell {
    @IBOutlet fileprivate weak var titleLbl: UILabel!
    @IBOutlet fileprivate weak var infoLbl: UILabel!
    @IBOutlet fileprivate weak var inputTxtFld: UITextField!
    
    fileprivate let disposeBag = DisposeBag()
    
    public var viewModel: UserTextCellViewModel? {
        didSet { didSetViewModel(self) }
    }
    
    public func decorate(_ decorator: UserTextCellDecoratorType,
                         _ info: UserInformation) {
        let keyboard = decorator.inputFieldKeyboard(info)
        inputTxtFld?.keyboardType = keyboard
    }
    
    fileprivate func didSetViewModel(_ cell: UserTextCell) {
        cell.setupViews(cell)
        cell.bindViewModel(cell)
    }
    
    fileprivate func setupViews(_ cell: UserTextCell) {
        guard let vm = cell.viewModel, let titleLbl = cell.titleLbl else {
            debugException()
            return
        }
        
        titleLbl.text = vm.userInformation.title()
    }
    
    fileprivate func bindViewModel(_ cell: UserTextCell) {
        guard
            let vm = cell.viewModel,
            let infoLbl = cell.infoLbl,
            let inputTxtFld = cell.inputTxtFld
        else {
            debugException()
            return
        }
        
        vm.setupBindings()
        
        let disposeBag = cell.disposeBag
        
        let propStream = vm.userPropertyStream()
            .mapNonNilOrEmpty()
            .distinctUntilChanged()
            .shareReplay(1)
        
        propStream
            .observeOnMain()
            .bind(to: infoLbl.rx.text)
            .disposed(by: disposeBag)
        
        propStream
            .observeOnMain()
            .bind(to: inputTxtFld.rx.text)
            .disposed(by: disposeBag)
        
        /// Skip 1 to skip placeholders, etc.
        inputTxtFld.rx.text.skip(1)
            .mapNonNilOrEmpty()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: vm.textInputTrigger())
            .disposed(by: disposeBag)
    }
}

public protocol UserTextCellDecoratorType {
    func inputFieldKeyboard(_ info: UserInformation) -> UIKeyboardType
}

public protocol UserTextCellModelType {
    var userInformation: UserInformation { get }
    
    func dbUserStream() -> Observable<Try<User>>
    
    func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>>
    
    func userProperty(_ user: User) -> String?
    
    func updateUserProperty(_ user: User, _ text: String) -> User
}

public struct UserTextCellModel: UserTextCellModelType {
    public let userInformation: UserInformation
    fileprivate let provider: SingletonType
    
    public init(_ provider: SingletonType, _ info: UserInformation) {
        self.provider = provider
        self.userInformation = info
    }
    
    public func dbUserStream() -> Observable<Try<User>> {
        return provider.trackedObjectManager.dbUserStream()
    }
    
    public func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>> {
        let prev = user.map({[$0]})
        let qos: DispatchQoS.QoSClass = .background
        return provider.dbRequestManager.upsertInMemory(prev, qos).map({$0.map(toVoid)})
    }
    
    public func userProperty(_ user: User) -> String? {
        fatalError("Must implement this for \(self)")
    }
    
    public func updateUserProperty(_ user: User, _ text: String) -> User {
        fatalError("Must implement this for \(self)")
    }
}

public struct UserNameTextCellModel: UserTextCellModelType {
    fileprivate let model: UserTextCellModelType
    
    public var userInformation: UserInformation {
        return model.userInformation
    }
    
    public init(_ provider: SingletonType, _ info: UserInformation) {
        self.model = UserTextCellModel(provider, info)
    }
    
    public func dbUserStream() -> Observable<Try<User>> {
        return model.dbUserStream()
    }
    
    public func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>> {
        return model.updateUserInDB(user)
    }
    
    public func userProperty(_ user: User) -> String? {
        return user.name
    }
    
    public func updateUserProperty(_ user: User, _ text: String) -> User {
        return user.cloneBuilder().with(name: text).build()
    }
}

public struct UserAgeTextCellModel: UserTextCellModelType {
    fileprivate let model: UserTextCellModelType
    
    public var userInformation: UserInformation {
        return model.userInformation
    }
    
    public init(_ provider: SingletonType, _ info: UserInformation) {
        self.model = UserTextCellModel(provider, info)
    }
    
    public func dbUserStream() -> Observable<Try<User>> {
        return model.dbUserStream()
    }
    
    public func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>> {
        return model.updateUserInDB(user)
    }
    
    public func userProperty(_ user: User) -> String? {
        return user.age.map({String(describing: $0)})
    }
    
    public func updateUserProperty(_ user: User, _ text: String) -> User {
        let age = Double(text).map({NSNumber(value: $0)}).getOrElse(0)
        return user.cloneBuilder().with(age: age).build()
    }
}

public struct UserTextCellViewModel {
    fileprivate let provider: SingletonType
    fileprivate let model: UserTextCellModelType
    fileprivate let textTrigger: BehaviorSubject<String?>
    fileprivate let disposeBag: DisposeBag
    
    public var userInformation: UserInformation {
        return model.userInformation
    }
    
    public init(_ provider: SingletonType, _ model: UserTextCellModelType) {
        self.provider = provider
        self.model = model
        disposeBag = DisposeBag()
        textTrigger = BehaviorSubject(value: nil)
    }
    
    public func setupBindings() {
        let disposeBag = self.disposeBag
        let model = self.model
        
        updatedUserOnTextTriggered()
            .flatMapLatest({model.updateUserInDB($0)})
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    public func userPropertyStream() -> Observable<Try<String>> {
        let model = self.model
        return model.dbUserStream().map({$0.flatMap({model.userProperty($0)})})
    }
    
    public func updatedUserOnTextTriggered() -> Observable<Try<User>> {
        let model = self.model
        
        return textInputStream()
            .mapNonNilOrEmpty()
            .withLatestFrom(model.dbUserStream(), resultSelector: {
                $1.zipWith(Optional.some($0), {model.updateUserProperty($0, $1)})
            })
    }
    
    public func textInputStream() -> Observable<String?> {
        return textTrigger.asObservable()
    }
    
    public func textInputTrigger() -> AnyObserver<String?> {
        return textTrigger.asObserver()
    }
}
