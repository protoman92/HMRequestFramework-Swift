//
//  UserProfileVC.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxDataSources
import RxSwift
import SwiftUtilities
import SwiftUIUtilities
import UIKit

public final class UserProfileVC: UIViewController {
    public typealias Section = SectionModel<String,UserInformation>
    public typealias DataSource = RxTableViewSectionedReloadDataSource<Section>
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var viewModel: UserProfileViewModel?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        /// This is actually not the correct implementation of MVVM, because
        /// the view model should be injected in by the controller that started
        /// the navigation process to this controller. However, for a simple
        /// exercise it will have to do.
        let model = UserProfileModel()
        viewModel = UserProfileViewModel(model)
        
        setupViews(self)
        bindViewModel(self)
    }
}

extension UserProfileVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    public func tableView(_ tableView: UITableView,
                          viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

public extension UserProfileVC {
    fileprivate func setupViews(_ controller: UserProfileVC) {
        guard let tableView = controller.tableView else {
            debugException()
            return
        }
        
        tableView.registerClass(UserTextCell.self)
    }
    
    fileprivate func setupDataSource(_ controller: UserProfileVC) -> DataSource {
        let dataSource = DataSource()
        
        dataSource.configureCell = {[weak controller] in
            if let controller = controller {
                return controller.configureCells($0, $1, $2, $3, controller)
            } else {
                return UITableViewCell()
            }
        }
        
        dataSource.canMoveRowAtIndexPath = {_ in false}
        dataSource.canEditRowAtIndexPath = {_ in false}
        return dataSource
    }
    
    fileprivate func configureCells(_ source: TableViewSectionedDataSource<Section>,
                                    _ tableView: UITableView,
                                    _ indexPath: IndexPath,
                                    _ item: Section.Item,
                                    _ controller: UserProfileVC)
        -> UITableViewCell
    {
        guard let vm = controller.viewModel else {
            debugException()
            return UITableViewCell()
        }
        
        if
            let cell = tableView.deque(UserTextCell.self, at: indexPath),
            let cm = vm.vmForUserTextCell(item)
        {
            cell.viewModel = cm
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

public extension UserProfileVC {
    fileprivate func bindViewModel(_ controller: UserProfileVC) {
        guard let tableView = controller.tableView else {
            debugException()
            return
        }
     
        let disposeBag = controller.disposeBag
        let dataSource = controller.setupDataSource(controller)
        
        tableView.rx.setDelegate(controller).disposed(by: disposeBag)
        
        Observable.just(UserInformation.allValues())
            .map({SectionModel(model: "", items: $0)})
            .map({[$0]})
            .observeOnMain()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}

public struct UserProfileModel {
    public init() {}
}

public struct UserProfileViewModel {
    fileprivate let model: UserProfileModel
    
    public init(_ model: UserProfileModel) {
        self.model = model
    }
    
    public func vmForUserTextCell(_ info: UserInformation) -> UserTextCellViewModel? {
        let model = UserTextCellModel()
        return UserTextCellViewModel(model)
    }
}
