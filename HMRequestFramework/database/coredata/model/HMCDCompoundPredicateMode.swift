//
//  HMCDCompoundPredicateMode.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this enum to specify how compound predicates should be constructed.
///
/// - and: AND mode.
/// - or: OR mode.
public enum HMCDCompoundPredicateMode {
    case and
    case or
    
    public func compoundMode() -> String {
        switch self {
        case .and: return "AND"
        case .or: return "OR"
        }
    }
}
