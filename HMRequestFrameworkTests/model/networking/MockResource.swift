//
//  MockResource.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/29/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public enum MockResource {
    case empty
}

extension MockResource: HMURLComponentProviderType {
    public func baseUrl() -> String {
        return "http://google.com"
    }
    
    public func endPoint() -> String {
        switch self {
        case .empty:
            return ""
        }
    }
}
