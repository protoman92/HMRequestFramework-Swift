//
//  HMErrorHolder.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 11/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

public struct HMErrorHolder {}

extension HMErrorHolder: Error {}

extension HMErrorHolder: HMMiddlewareGlobalApplicableType {
    public typealias Filterable = String
}
