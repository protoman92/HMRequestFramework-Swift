//
//  HMDBStreamEvent.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this enum to represent stream events from DB.
///
/// - willChange: Used when the underlying DB is about to change data.
/// - didChange: Used when the underlying DB has changed data.
/// - inserted: Used when some objects were inserted.
/// - dummy: Used when we cannot categorize this even anywhere else.
public enum HMDBStreamEvent<V> {
    case willChange
    case didChange
    case inserted([V])
    case dummy
    
    /// Map the current enum case to the same case with a different generic.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMDBStreamEvent instance.
    public func map<V2>(_ f: (V) throws -> V2) -> HMDBStreamEvent<V2> {
        switch self {
        case .inserted(let values):
            return .inserted(values.flatMap({try? f($0)}))
            
        case .willChange:
            return .willChange
            
        case .didChange:
            return .didChange
            
        case .dummy:
            return .dummy
        }
    }
}
