//
//  UserProfileVC.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMReactiveRedux
import HMRequestFramework
import RxDataSources
import RxSwift
import SwiftFP
import SwiftUIUtilities
import UIKit

public final class UserProfileVC: UIViewController {
  public typealias Section = SectionModel<String,UserInformation>
  public typealias DataSource = RxTableViewSectionedReloadDataSource<Section>

  @IBOutlet fileprivate weak var nameLbl: UILabel!
  @IBOutlet fileprivate weak var ageLbl: UILabel!
  @IBOutlet fileprivate weak var visibleLbl: UILabel!
  @IBOutlet fileprivate weak var tableView: UITableView!
  @IBOutlet fileprivate weak var persistBtn: UIButton!

  fileprivate var insertUserBtn: UIBarButtonItem? {
    return navigationItem.rightBarButtonItem
  }

  fileprivate let disposeBag = DisposeBag()
  fileprivate let decorator = UserProfileVCDecorator()

  public var viewModel: UserProfileViewModel?

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupViews(self)
    bindViewModel(self)
  }
}

extension UserProfileVC: UITableViewDelegate {
  public func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
    return 1
  }

  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 100
  }

  public func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }

  public func tableView(_ tableView: UITableView,
                        viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}

public extension UserProfileVC {
  fileprivate func setupViews(_ controller: UserProfileVC) {
    guard let tableView = controller.tableView else { return }
    tableView.registerNib(UserTextCell.self)

    controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Insert new user",
      style: .done,
      target: nil,
      action: nil)
  }

  fileprivate func setupDataSource(_ controller: UserProfileVC) -> DataSource {
    let dataSource = DataSource(configureCell: {[weak controller] in
      if let controller = controller {
        return controller.configureCells($0, $1, $2, $3, controller)
      } else {
        return UITableViewCell()
      }
    })

    dataSource.canMoveRowAtIndexPath = {(_, _) in false}
    dataSource.canEditRowAtIndexPath = {(_, _) in false}
    return dataSource
  }

  fileprivate func configureCells(_ source: TableViewSectionedDataSource<Section>,
                                  _ tableView: UITableView,
                                  _ indexPath: IndexPath,
                                  _ item: Section.Item,
                                  _ controller: UserProfileVC)
    -> UITableViewCell
  {
    guard let vm = controller.viewModel else { return UITableViewCell() }
    
    let decorator = controller.decorator

    if
      let cell = tableView.deque(UserTextCell.self, at: indexPath),
      let cm = vm.vmForUserTextCell(item)
    {
      cell.viewModel = cm
      cell.decorate(decorator, item)
      return cell
    } else {
      return UITableViewCell()
    }
  }
}

public extension UserProfileVC {
  fileprivate func bindViewModel(_ controller: UserProfileVC) {
    guard
      let vm = controller.viewModel,
      let tableView = controller.tableView,
      let insertUserBtn = controller.insertUserBtn,
      let persistBtn = controller.persistBtn,
      let nameLbl = controller.nameLbl,
      let ageLbl = controller.ageLbl,
      let visibleLbl = controller.visibleLbl
      else {
        return
    }

    vm.setupBindings()

    let disposeBag = controller.disposeBag
    let dataSource = controller.setupDataSource(controller)

    tableView.rx.setDelegate(controller).disposed(by: disposeBag)

    Observable.just(UserInformation.allValues())
      .map({SectionModel(model: "", items: $0)})
      .map({[$0]})
      .observeOnMain()
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

    vm.userNameStream()
      .mapNonNilOrElse({$0.value}, "No information yet")
      .observeOnMain()
      .bind(to: nameLbl.rx.text)
      .disposed(by: disposeBag)

    vm.userAgeStream()
      .mapNonNilOrElse({$0.value}, "No information yet")
      .observeOnMain()
      .bind(to: ageLbl.rx.text)
      .disposed(by: disposeBag)

    vm.userVisibilityStream()
      .mapNonNilOrElse({$0.value}, "No information yet")
      .observeOnMain()
      .bind(to: visibleLbl.rx.text)
      .disposed(by: disposeBag)

    insertUserBtn.rx.tap
      .throttle(0.3, scheduler: MainScheduler.instance)
      .bind(to: vm.insertUserTrigger())
      .disposed(by: disposeBag)

    persistBtn.rx.tap
      .throttle(0.3, scheduler: MainScheduler.instance)
      .bind(to: vm.persistDataTrigger())
      .disposed(by: disposeBag)
  }
}

public struct UserProfileVCDecorator: UserTextCellDecoratorType {
  public func inputFieldKeyboard(_ info: UserInformation) -> UIKeyboardType {
    switch info {
    case .age: return .numberPad
    case .name: return .default
    }
  }
}

public struct UserProfileModel {
  fileprivate let provider: SingletonType

  public init(_ provider: SingletonType) {
    self.provider = provider
  }

  public func dbUserStream() -> Observable<Try<User>> {
    return provider.trackedObjectManager.dbUserStream()
  }

  public func updateUserInDB(_ user: Try<User>) -> Observable<Try<Void>> {
    let requestManager = provider.dbRequestManager
    let prev = user.map({[$0]})
    let qos: DispatchQoS.QoSClass = .background
    return requestManager.upsertInMemory(prev, qos).map({$0.map({_ in})})
  }

  public func persistToDB<Prev>(_ prev: Try<Prev>) -> Observable<Try<Void>> {
    let requestManager = provider.dbRequestManager
    let qos: DispatchQoS.QoSClass = .background
    return requestManager.persistToDB(prev, qos)
  }

  public func userName(_ user: User) -> String {
    return "Name: \(user.name.getOrElse(""))"
  }

  public func userAge(_ user: User) -> String {
    return "Age: \(user.age.getOrElse(0))"
  }

  public func userVisibility(_ user: User) -> String {
    return "Visibility: \(user.visible.map({$0.boolValue}).getOrElse(false))"
  }
}

public struct UserProfileViewModel {
  fileprivate let provider: SingletonType
  fileprivate let model: UserProfileModel
  fileprivate let disposeBag: DisposeBag
  fileprivate let insertUser: PublishSubject<Void>
  fileprivate let persistData: PublishSubject<Void>

  public init(_ provider: SingletonType, _ model: UserProfileModel) {
    self.provider = provider
    self.model = model
    disposeBag = DisposeBag()
    insertUser = PublishSubject()
    persistData = PublishSubject()
  }

  public func setupBindings() {
    let provider = self.provider
    let disposeBag = self.disposeBag
    let model = self.model
    let actionTrigger = provider.reduxStore.actionTrigger()
    let insertTriggered = userOnInsertTriggered().share(replay: 1)

    let insertPerformed = insertTriggered
      .map(Try.success)
      .flatMapLatest({model.updateUserInDB($0)})
      .share(replay: 1)

    let persistTriggered = persistDataStream().share(replay: 1)

    let persistPerformed = persistTriggered
      .map(Try.success)
      .flatMapLatest({model.persistToDB($0)})
      .share(replay: 1)

    Observable<Error>
      .merge(insertPerformed.mapNonNilOrEmpty({$0.error}),
             persistPerformed.mapNonNilOrEmpty({$0.error}))
      .map(GeneralReduxAction.Error.Display.updateShowError)
      .observeOnMain()
      .bind(to: actionTrigger)
      .disposed(by: disposeBag)

    Observable<Bool>
      .merge(insertTriggered.map({_ in true}),
             insertPerformed.map({_ in false}),
             persistTriggered.map({_ in true}),
             persistPerformed.map({_ in false}))
      .map(GeneralReduxAction.Progress.Display.updateShowProgress)
      .observeOnMain()
      .bind(to: actionTrigger)
      .disposed(by: disposeBag)
  }

  public func vmForUserTextCell(_ info: UserInformation) -> UserTextCellViewModel? {
    let provider = self.provider

    switch info {
    case .age:
      let model = UserAgeTextCellModel(provider)
      return UserTextCellViewModel(provider, model)

    case .name:
      let model = UserNameTextCellModel(provider)
      return UserTextCellViewModel(provider, model)
    }
  }

  public func userNameStream() -> Observable<Try<String>> {
    let model = self.model
    return model.dbUserStream().map({$0.map({model.userName($0)})})
  }

  public func userAgeStream() -> Observable<Try<String>> {
    let model = self.model
    return model.dbUserStream().map({$0.map({model.userAge($0)})})
  }

  public func userVisibilityStream() -> Observable<Try<String>> {
    let model = self.model
    return model.dbUserStream().map({$0.map({model.userVisibility($0)})})
  }

  public func insertUserTrigger() -> AnyObserver<Void> {
    return insertUser.asObserver()
  }

  public func insertUserStream() -> Observable<Void> {
    return insertUser.asObservable()
  }

  public func userOnInsertTriggered() -> Observable<User> {
    return insertUserStream().map({User.builder()
      .with(name: "Hai Pham - \(String.random(withLength: 5))")
      .with(id: UUID().uuidString)
      .with(age: NSNumber(value: Int.randomBetween(10, 99)))
      .with(visible: NSNumber(value: true))
      .build()
    })
  }

  public func persistDataTrigger() -> AnyObserver<Void> {
    return persistData.asObserver()
  }

  public func persistDataStream() -> Observable<Void> {
    return persistData.asObservable()
  }
}
