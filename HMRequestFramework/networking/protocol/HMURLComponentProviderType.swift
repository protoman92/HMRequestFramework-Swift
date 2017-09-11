//
//  HMURLComponentProviderType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 18/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

public protocol HMURLComponentProviderType: HMNetworkResourceType {
    func endPoint() throws -> String
}

public extension HMURLComponentProviderType {
    
    /// Get the base urlString using baseUrl and endPoint().
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if the baseUrl and endPoint are not available.
    func urlString() throws -> String {
        return try endPoint()
    }
}
