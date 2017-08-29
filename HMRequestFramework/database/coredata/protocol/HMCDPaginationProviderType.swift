//
//  HMCDPaginationProviderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

/// Classes that implement this protocol should provide pagination properties
/// to be used in event streaming.
public protocol HMCDPaginationProviderType: HMCDPaginationMultipleType {
    
    /// Specify the fetch limit for a fetch request. This determines how many
    /// items are fetched from DB every time a stream requests for more data.
    ///
    /// - Returns: An Int value.
    func fetchLimit() -> UInt
    
    /// Specify the fetch offset for a fetch request. This determines the cut
    /// off at which data start being collected.
    ///
    /// - Returns: An Int value.
    func fetchOffset() -> UInt
    
    /// Specify the pagination mode.
    ///
    /// - Returns: A HMCDPaginationMode instance.
    func paginationMode() -> HMCDPaginationMode
}

public extension HMCDPaginationProviderType {
    public func fetchLimitWithMultiple(_ multiple: UInt) -> UInt {
        let fetchLimit = self.fetchLimit()
        
        switch paginationMode() {
        case .fixedPageCount:
            return fetchLimit
            
        case .variablePageCount:
            return fetchLimit * multiple
        }
    }
    
    // If paginationMode is fixedPageCount, we need to increment the fetchOffset
    // by multiples of fetchLimit to simulate page flipping. We also need to
    // decrement the multiple by 1 because we need the first page's fetchOffset
    // to be the base fetchOffset (in case the multiple is 0 or larger than 1).
    public func fetchOffsetWithMultiple(_ multiple: UInt) -> UInt {
        let fetchOffset = self.fetchOffset()
        let fetchLimit = self.fetchLimit()
        
        switch paginationMode() {
        case .fixedPageCount:
            return fetchOffset + fetchLimit * (Swift.max(multiple, 1) - 1)
            
        case .variablePageCount:
            return fetchOffset
        }
    }
}
