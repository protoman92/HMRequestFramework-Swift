//
//  HMIdentifiables.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Utility class for identifiable objects.
public final class HMIdentifiables {
    
    /// Segment the key-value pairs into buckets, based on the keys.
    ///
    /// - Parameter ids: A Sequence of HMIdentifiableType.
    /// - Returns: A Dictionary instance.
    public static func segment<S>(_ ids: S) -> [String : [String]] where
        S: Sequence, S.Element == HMIdentifiableType
    {
        var segments: [String : [String]] = [:]
        
        for identifiable in ids {
            if let value = identifiable.primaryValue() {
                let key = identifiable.primaryKey()
                
                if segments[key] == nil {
                    segments[key] = [String]()
                }
                
                segments[key]?.append(value)
            }
        }
        
        return segments
    }
    
    /// Segment the key-value pairs into buckets, based on the keys.
    ///
    /// - Parameter ids: A Sequence of HMIdentifiableType.
    /// - Returns: A Dictionary instance.
    public static func segment<ID,S>(_ ids: S) -> [String : [String]] where
        ID: HMIdentifiableType,
        S: Sequence,
        S.Element == ID
    {
        return segment(ids.map({$0 as HMIdentifiableType}))
    }
}
