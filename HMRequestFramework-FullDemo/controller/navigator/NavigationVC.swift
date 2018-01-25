//
//  NavigationVC.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 20/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMReactiveRedux
import MRProgress
import RxSwift
import SwiftUtilities
import UIKit

public final class NavigationVC: UINavigationController {
    public var viewModel: NavigationViewModel?
    
    fileprivate let disposeBag = DisposeBag()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel(self)
    }
}

public extension NavigationVC {
    fileprivate func displayError(_ error: Error, _ controller: NavigationVC) {
        let alert = UIAlertController(title: "Error!",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        controller.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func displayProgress(_ enabled: Bool, _ controller: NavigationVC) {
//        guard let view = controller.view else {
//            debugException()
//            return
//        }
//
//        if enabled {
//            MRProgressOverlayView.showOverlayAdded(to: view, animated: true)
//        } else {
//            MRProgressOverlayView.dismissOverlay(for: view, animated: true)
//        }
        print("Displaying progress: \(enabled)")
    }
    
    fileprivate func bindViewModel(_ controller: NavigationVC) {
        guard let vm = controller.viewModel else {
            debugException()
            return
        }
        
        vm.setupBindings()
        
        let disposeBag = controller.disposeBag
        
        vm.errorStream()
            .mapNonNilOrEmpty()
            .observeOnMain()
            .doOnNext({[weak controller] error in
                controller.map({$0.displayError(error, $0)})
            })
            .doOnNext({_ in vm.clearError()})
            .subscribe()
            .disposed(by: disposeBag)
        
        vm.progressStream()
            .mapNonNilOrEmpty()
            .distinctUntilChanged()
            .observeOnMain()
            .doOnNext({[weak controller] progress in
                controller.map({$0.displayProgress(progress, $0)})
            })
            .subscribe()
            .disposed(by: disposeBag)
    }
}

public struct NavigationModel {
    fileprivate let provider: SingletonType
    
    public init(_ provider: SingletonType) {
        self.provider = provider
    }
}

public struct NavigationViewModel {
    fileprivate let provider: SingletonType
    fileprivate let navigator: NavigationServiceType
    fileprivate let disposeBag: DisposeBag
    fileprivate let goToMain: PublishSubject<Void>
    
    public init(_ provider: SingletonType, _ navigator: NavigationServiceType) {
        self.provider = provider
        self.navigator = navigator
        disposeBag = DisposeBag()
        goToMain = PublishSubject()
    }
    
    public func setupBindings() {
        let disposeBag = self.disposeBag
        
        goToMainStream()
            .startWith(())
            .observeOnMain()
            .doOnNext({self.goToMainScreen()})
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    public func goToMainTrigger() -> AnyObserver<Void> {
        return goToMain.asObserver()
    }
    
    public func goToMainStream() -> Observable<Void> {
        return goToMain.asObservable()
    }
    
    fileprivate func goToMainScreen() {
        let vm = MainViewModel(provider, navigator)
        navigator.navigate(vm)
    }
    
    public func errorStream() -> Observable<Error?> {
        let path = HMGeneralReduxAction.Error.Display.errorPath
        return provider.reduxStore.stateValueStream(Error.self, path)
    }
    
    public func progressStream() -> Observable<Bool?> {
        let path = HMGeneralReduxAction.Progress.Display.progressPath
        return provider.reduxStore.stateValueStream(Bool.self, path)
    }
    
    public func clearError() {
        let store = provider.reduxStore
        let action = HMGeneralReduxAction.Error.Display.updateShowError(nil)
        mainThread({store.dispatch(action)})
    }
}
