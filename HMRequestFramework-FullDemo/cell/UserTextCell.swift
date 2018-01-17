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
    
    fileprivate func didSetViewModel(_ cell: UserTextCell) {
        cell.setupViews(cell)
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
        
        let disposeBag = cell.disposeBag
        
        vm.userPropertyStream()
            .distinctUntilChanged()
            .observeOnMain()
            .bind(to: infoLbl.rx.text)
            .disposed(by: disposeBag)
    }
}

public protocol UserTextCellModelType {
    var userInformation: UserInformation { get }
    
    func dbUserStream() -> Observable<Try<User>>
    
    func userProperty(_ user: User) -> String?
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
    
    public func userProperty(_ user: User) -> String? {
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
    
    public func userProperty(_ user: User) -> String? {
        return user.name
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
    
    public func userProperty(_ user: User) -> String? {
        return user.age.map({String(describing: $0)})
    }
}

public struct UserTextCellViewModel {
    fileprivate let provider: SingletonType
    fileprivate let model: UserTextCellModelType
    
    public var userInformation: UserInformation {
        return model.userInformation
    }
    
    public init(_ provider: SingletonType, _ model: UserTextCellModelType) {
        self.provider = provider
        self.model = model
    }
    
    public func userPropertyStream() -> Observable<String> {
        let model = self.model
        
        return model.dbUserStream()
            .map({$0.flatMap({model.userProperty($0)})})
            .map({
                do {
                    return try $0.getOrThrow()
                } catch let e {
                    return e.localizedDescription
                }
            })
    }
}
