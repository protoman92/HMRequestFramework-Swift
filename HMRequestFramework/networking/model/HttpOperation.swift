//
//  HttpMethod.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

public enum HttpOperation: EnumerableType {
    case get
    case post
    case head
    case put
    case upload
    
    public static func allValues() -> [HttpOperation] {
        return [.get, .post, .head, .put]
    }
    
    public func method() -> String {
        switch self {
        case .get:
            return "GET"
            
        case .post, .upload:
            return "POST"
            
        case .head:
            return "HEAD"
            
        case .put:
            return "PUT"
        }
    }
    
    /// Check if the current method requires a HTTP body.
    ///
    /// - Returns: A Bool value.
    public func requiresBody() -> Bool {
        switch self {
        case .post, .put, .upload:
            return true;
            
        default:
            return false
        }
    }
}
