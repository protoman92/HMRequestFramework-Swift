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
    func url() throws -> URL {
        if let url = try URL(string: "\(baseUrl())/\(endPoint())") {
            return url
        } else {
            throw Exception("URL cannot be constructed")
        }
    }
}
