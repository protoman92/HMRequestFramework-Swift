//
//  HMRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 6/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Base request type that can be used for HMRequestHandler.
public protocol HMRequestType {

    /// Specify how many times a request should be retries.
    ///
    /// - Returns: An Int value.
    func retries() -> Int
}
