//
//  NavigationService.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 20/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import SwiftUtilities
import UIKit

public protocol NavigationServiceType {
    func navigate(_ viewModel: Any)
}

public struct NavigationService: NavigationServiceType {
    fileprivate let navigator: UINavigationController
    
    public init(_ navigator: UINavigationController) {
        self.navigator = navigator
    }
    
    public func navigate(_ viewModel: Any) {
        switch viewModel {
        case let vm as MainViewModel:
            goToMain(navigator, vm)
            
        case let vm as UserProfileViewModel:
            goToProfile(navigator, vm)
            
        default:
            debugException()
            break
        }
    }
    
    fileprivate func goToMain(_ controller: UINavigationController,
                              _ vm: MainViewModel) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let id = "MainVC"
        
        if let vc = storyboard.instantiateViewController(withIdentifier: id) as? MainVC {
            vc.viewModel = vm
            controller.pushViewController(vc, animated: true)
        } else {
            debugException()
        }
    }
    
    fileprivate func goToProfile(_ controller: UINavigationController,
                                 _ vm: UserProfileViewModel) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let id = "UserProfileVC"
        
        if let vc = storyboard.instantiateViewController(withIdentifier: id) as? UserProfileVC {
            vc.viewModel = vm
            controller.pushViewController(vc, animated: true)
        } else {
            debugException()
        }
    }
}
