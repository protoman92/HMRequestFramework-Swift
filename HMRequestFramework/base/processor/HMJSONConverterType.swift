//
//  HMJSONConverterType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 3/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must provide methods to convert some
/// object into JSON. We should use this approach instead of asking the data
/// classes to implement JSONConvertibleType because there are some data that
/// should be kept out of said classes (e.g. device timezone).
public protocol HMJSONConverterType {
    
}
