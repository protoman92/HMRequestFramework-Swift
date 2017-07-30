//
//  HMJSONConvertibleType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must be convertible to JSON.
public protocol HMJSONConvertibleType {
    func toJSON() -> [String : Any]
}
