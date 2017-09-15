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
    case patch
    case head
    case put
    case upload
    
    public static func allValues() -> [HttpOperation] {
        return [.get, .post, .patch, .head, .put, .upload]
    }
    
    public func method() -> String {
        switch self {
        case .get:
            return "GET"
            
        case .post, .upload:
            return "POST"
            
        case .patch:
            return "PATCH"
            
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
        case .post, .put, .upload, .patch:
            return true;
            
        default:
            return false
        }
    }
}
