//
//  HMCDVersionUpdateRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this typealias for CoreData version update request.
public typealias HMCDVersionUpdateRequest = HMVersionUpdateRequest<HMCDVersionableType>

public extension HMVersionUpdateRequest where VC == HMCDVersionableType {
    
    /// Compare the current request against another request.
    ///
    /// - Parameter item: A HMVersionUpdateRequest instance.
    /// - Returns: A Bool value.
    public func compare(against item: HMVersionUpdateRequest<HMCDVersionableType>) -> Bool {
        if let vc1 = try? self.editedVC(), let vc2 = try? item.editedVC() {
            return vc1.compare(against: vc2)
        } else {
            return false
        }
    }
}
