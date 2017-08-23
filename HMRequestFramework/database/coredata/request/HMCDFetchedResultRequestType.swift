//
//  HMCDFetchedResultRequestType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/23/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol must be able to provide the required
/// parameters for a FRC instance.
public protocol HMCDFetchedResultRequestType: HMCDFetchRequestType {
    
    /// Section name to be used to group date as fetched by the FRC.
    ///
    /// - Returns: A String value.
    func frcSectionName() -> String?
    
    /// Cache name to identify a local cache or create one if it does not exist
    /// yet.
    ///
    /// - Returns: A String value.
    func frcCacheName() -> String?
}
