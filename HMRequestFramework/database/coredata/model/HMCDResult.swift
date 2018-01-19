//
//  HMCDResult.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/13/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// The generic for this typealias should be wide enough to be useful for
/// multiple use cases.
///
/// We should not publish the managed objects here because they may be gone
/// after the contexts holding them are gone. Instead, publish only the identity
/// value. For e.g., HMCDObjectConvertibleType's stringRepresentationForResult
/// will be used for save/upsert/version-update operations.
public typealias HMCDResult = HMResult<String>
