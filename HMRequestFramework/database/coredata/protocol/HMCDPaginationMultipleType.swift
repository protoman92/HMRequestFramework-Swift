//
//  HMCDPaginationMultipleType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must be able to provide pagination
/// information by multiple that will be continually increase (for e.g. everytime
/// an user swipes to load more).
public protocol HMCDPaginationMultipleType {
    
    /// Specify the fetch limit with a multiple.
    ///
    /// - Parameter multiple: An Int value.
    /// - Returns: An Int value.
    func fetchLimitWithMultiple(_ multiple: UInt) -> UInt
    
    /// Specify the amount with which to increment fetch offset.
    ///
    /// - Parameter multiple: An Int value.
    /// - Returns: An Int value.
    func fetchOffsetWithMultiple(_ multiple: UInt) -> UInt
}
