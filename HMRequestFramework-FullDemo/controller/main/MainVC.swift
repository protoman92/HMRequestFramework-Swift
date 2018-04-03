//
//  MainVC.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 20/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities
import UIKit

public final class MainVC: UIViewController {
  @IBOutlet fileprivate var goToProfile: UIButton!

  fileprivate let disposeBag = DisposeBag()

  public var viewModel: MainViewModel?

  override public func viewDidLoad() {
    super.viewDidLoad()
    bindViewModel(self)
  }
}

public extension MainVC {
  fileprivate func bindViewModel(_ controller: MainVC) {
    guard
      let vm = controller.viewModel,
      let goToProfile = controller.goToProfile
    else {
      debugException()
      return
    }

    vm.setupBindings()

    let disposeBag = controller.disposeBag

    goToProfile.rx.tap
      .throttle(1, scheduler: MainScheduler.instance)
      .bind(to: vm.goToProfileTrigger())
      .disposed(by: disposeBag)
  }
}

public struct MainViewModel {
  fileprivate let provider: SingletonType
  fileprivate let navigator: NavigationServiceType
  fileprivate let disposeBag: DisposeBag
  fileprivate let goToProfile: PublishSubject<Void>

  public init(_ provider: SingletonType, _ navigator: NavigationServiceType) {
    self.provider = provider
    self.navigator = navigator
    disposeBag = DisposeBag()
    goToProfile = PublishSubject()
  }

  public func setupBindings() {
    let disposeBag = self.disposeBag

    goToProfileStream()
      .observeOnMain()
      .doOnNext({self.goToProfileScreen()})
      .subscribe()
      .disposed(by: disposeBag)
  }

  public func goToProfileTrigger() -> AnyObserver<Void> {
    return goToProfile.asObserver()
  }

  public func goToProfileStream() -> Observable<Void> {
    return goToProfile.asObservable()
  }

  fileprivate func goToProfileScreen() {
    let model = UserProfileModel(provider)
    let vm = UserProfileViewModel(provider, model)
    navigator.navigate(vm)
  }
}
