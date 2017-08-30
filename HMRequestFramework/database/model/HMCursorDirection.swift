//
//  HMCursorDirection.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 30/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// In a paginated DB stream, this enum provides a means to determine backward
/// or forward pagination.
///
/// - backward: Go back 1 page.
/// - remain: Remain on the same page and reload items if needed.
/// - forward: Go forward 1 page.
public enum HMCursorDirection: Int {
    case backward = -1
    case remain = 0
    case forward = 1
    
    /// We do not care how large the value is, just whether it is positive or
    /// not.
    ///
    /// - Parameter value: An Int value.
    public init(from value: Int) {
        if value > 0 {
            self = .forward
        } else if value < 0 {
            self = .backward
        } else {
            self = .remain
        }
    }
}

extension HMCursorDirection: EnumerableType {
    public static func allValues() -> [HMCursorDirection] {
        return [.backward, .remain, .forward]
    }
}
