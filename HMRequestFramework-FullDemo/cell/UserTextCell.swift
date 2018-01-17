//
//  UserTextCell.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import UIKit

public final class UserTextCell: UITableViewCell {
    @IBOutlet fileprivate weak var titleLbl: UILabel!
    @IBOutlet fileprivate weak var infoLbl: UILabel!
    @IBOutlet fileprivate weak var inputTxtFld: UITextField!
    
    public var viewModel: UserTextCellViewModel?
}

public struct UserTextCellModel {
    
}

public struct UserTextCellViewModel {
    fileprivate let model: UserTextCellModel
    
    public init(_ model: UserTextCellModel) {
        self.model = model
    }
}
