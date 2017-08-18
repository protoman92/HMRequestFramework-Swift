//
//  HMNetworkResourceType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

public protocol HMNetworkResourceType {
    
    /// Get the URL endpoint for Http operations.
    ///
    /// - Returns: A String value.
    /// - Throws: Exception if the url is not available.
    func urlString() throws -> String
}

public extension HMNetworkResourceType {
    
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
