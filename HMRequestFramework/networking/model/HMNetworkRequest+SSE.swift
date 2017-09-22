//
//  HMNetworkRequest+SSE.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager

// MARK: - SSE-compatible.
public extension HMNetworkRequest {
    
    /// Convert the current network request to a SSE request for SSE-related
    /// streaming.
    ///
    /// - Returns: A HMSSERequest instance.
    public func asSSERequest() -> HMSSERequest {
        return HMSSERequest.builder()
            .with(urlString: try? self.urlString())
            .with(headers: self.headers() as [String : Any]?)
            .with(retryDelay: self.retryDelay())
            .build()
    }
}
