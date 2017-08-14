//
//  HttpMethod.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

public enum HttpMethod: String, EnumerableType {
    case get = "GET"
    case post = "POST"
    case head = "HEAD"
    case put = "PUT"
    
    public static func allValues() -> [HttpMethod] {
        return [.get, .post, .head, .put]
    }
    
    /// Check if the current method requires a HTTP body.
    ///
    /// - Returns: A Bool value.
    public func requiresBody() -> Bool {
        switch self {
        case .post, .put:
            return true;
            
        default:
            return false
        }
    }
}
