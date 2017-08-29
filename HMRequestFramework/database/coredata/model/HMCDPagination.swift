//
//  HMCDPagination.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Default pagination provider class.
public struct HMCDPagination {
    fileprivate var cdFetchLimit: UInt
    fileprivate var cdFetchOffset: UInt
    fileprivate var cdPaginationMode: HMCDPaginationMode
    
    fileprivate init() {
        cdFetchLimit = 0
        cdFetchOffset = 0
        cdPaginationMode = .variablePageCount
    }
}

extension HMCDPagination: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var pagination: Buildable
        
        fileprivate init() {
            pagination = HMCDPagination()
        }
        
        /// Set the fetch limit.
        ///
        /// - Parameter fetchLimit: An Int value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(fetchLimit: UInt) -> Self {
            pagination.cdFetchLimit = fetchLimit
            return self
        }
        
        /// Set the fetch offset.
        ///
        /// - Parameter fetchOffset: An Int value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(fetchOffset: UInt) -> Self {
            pagination.cdFetchOffset = fetchOffset
            return self
        }
        
        /// Set the pagination mode.
        ///
        /// - Parameter paginationMode: A HMCDPaginationMode instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(paginationMode: HMCDPaginationMode) -> Self {
            pagination.cdPaginationMode = paginationMode
            return self
        }
    }
}

extension HMCDPagination.Builder: HMProtocolConvertibleBuilderType {
    public typealias Buildable = HMCDPagination
    
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return with(generic: buildable)
    }
    
    @discardableResult
    public func with(generic: Buildable.PTCType) -> Self {
        return self
            .with(fetchLimit: generic.fetchLimit())
            .with(fetchOffset: generic.fetchOffset())
            .with(paginationMode: generic.paginationMode())
    }
    
    public func build() -> Buildable {
        return pagination
    }
}

extension HMCDPagination: HMProtocolConvertibleType {
    public typealias PTCType = HMCDPaginationProviderType
    
    public func asProtocol() -> HMCDPaginationProviderType {
        return self
    }
}

extension HMCDPagination: HMCDPaginationProviderType {
    public func fetchLimit() -> UInt {
        return cdFetchLimit
    }
    
    public func fetchOffset() -> UInt {
        return cdFetchOffset
    }
    
    public func paginationMode() -> HMCDPaginationMode {
        return cdPaginationMode
    }
}
