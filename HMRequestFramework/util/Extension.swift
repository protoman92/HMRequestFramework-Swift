//
//  Extension.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 15/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import Differentiator

/// There might be an extension for these types in RxDataSources, but since we
/// do not include UIKit in this repository, we need to define custom extensions
/// below.
extension Int: IdentifiableType {
    public typealias Identity = Int
    
    public var identity: Identity {
        return self
    }
}

extension String: IdentifiableType {
    public typealias Identity = String
    
    public var identity: Identity {
        return self
    }
}
