//
//  HMCDMainContextMode.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 29/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this enum to determine how the main context should be constructed.
///
/// - background: Main context shall be a context with a background thread.
/// - mainThread: Main context shall be a context on the main thread.
public enum HMCDMainContextMode {
    case background
    case mainThread
}
