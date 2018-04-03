//
//  UserInformation.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import SwiftUtilities

public enum UserInformation: EnumerableType {
  case name
  case age

  public static func allValues() -> [UserInformation] {
    return [name, age]
  }

  public func title() -> String {
    switch self {
    case .name:     return "Name"
    case .age:      return "Age"
    }
  }
}
