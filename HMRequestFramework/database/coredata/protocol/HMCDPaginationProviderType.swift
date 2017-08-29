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
    func fetchLimit() -> Int
    
    /// Specify the fetch offset for a fetch request. This determines the cut
    /// off at which data start being collected.
    ///
    /// - Returns: An Int value.
    func fetchOffset() -> Int
    
    /// Specify the pagination mode.
    ///
    /// - Returns: A HMCDPaginationMode instance.
    func paginationMode() -> HMCDPaginationMode
}

public extension HMCDPaginationProviderType {
    public func fetchLimitWithMultiple(_ multiple: Int) -> Int {
        let fetchLimit = self.fetchLimit()
        
        switch paginationMode() {
        case .fixedPageCount: return fetchLimit
        case .variablePageCount: return fetchLimit * multiple
        }
    }
    
    public func fetchOffsetWithMultiple(_ multiple: Int) -> Int {
        let fetchOffset = self.fetchOffset()
        
        switch paginationMode() {
        case .fixedPageCount: return fetchOffset * multiple
        case .variablePageCount: return fetchOffset
        }
    }
}
