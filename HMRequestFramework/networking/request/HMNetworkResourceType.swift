//
//  HMNetworkResourceType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

public protocol HMNetworkResourceType {
    func baseUrl() throws -> String
    
    func endPoint() throws -> String
}

public extension HMNetworkResourceType {
    
    /// Get the base urlString using baseUrl and endPoint().
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if the baseUrl and endPoint are not available.
    func urlString() throws -> String {
        return try "\(baseUrl())/\(endPoint())"
    }
    
    /// Get the URL for a URLRequest.
    ///
    /// - Returns: A URL instance.
    /// - Throws: Exception if the URL cannot be generated.
    func url() throws -> URL {
        if let url = try URL(string: urlString()) {
            return url
        } else {
            throw Exception("URL cannot be constructed")
        }
    }
}
