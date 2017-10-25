//
//  HMCDTextSearchRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 25/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// This class provides the necessary parameters for a CoreData text search
/// request.
public struct HMCDTextSearchRequest {
    public enum Comparison {
        case beginsWith
        case contains
        
        fileprivate func comparison() -> String {
            switch self {
            case .beginsWith: return "BEGINSWITH"
            case .contains: return "CONTAINS"
            }
        }
    }
    
    public enum Modifier {
        case caseInsensitive
        case diacriticInsensitive
        
        fileprivate func modifier() -> String {
            switch self {
            case .caseInsensitive: return "c"
            case .diacriticInsensitive: return "d"
            }
        }
    }
    
    fileprivate var pKey: String?
    fileprivate var pValue: String?
    fileprivate var pComparison: Comparison?
    fileprivate var pModifiers: [Modifier]
    
    fileprivate init() {
        pModifiers = []
    }
}

public extension HMCDTextSearchRequest {
    
    /// Get the predicate to perform a text search.
    ///
    /// - Returns: A NSPredicate instance.
    /// - Throws: Exception if arguments are not available.
    public func textSearchPredicate() throws -> NSPredicate {
        guard
            let key = self.pKey,
            let value = self.pValue,
            let comparison = self.pComparison
        else {
            throw Exception("Some arguments are nil")
        }
        
        let modifiers = self.pModifiers.map({$0.modifier()})
        
        let modifierString = modifiers.isEmpty
            ? ""
            : "[\(modifiers.joined(separator: ""))]"
        
        let format = "%K \(comparison.comparison())\(modifierString) %@"
        return NSPredicate(format: format, key, value)
    }
}

extension HMCDTextSearchRequest: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: Buildable
        
        fileprivate init() {
            request = Buildable()
        }
        
        /// Set the request key.
        ///
        /// - Parameter key: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(key: String?) -> Self {
            request.pKey = key
            return self
        }
        
        /// Set the request value.
        ///
        /// - Parameter value: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(value: String?) -> Self {
            request.pValue = value
            return self
        }
        
        /// Set the request comparison.
        ///
        /// - Parameter comparison: A Comparison instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(comparison: Comparison?) -> Self {
            request.pComparison = comparison
            return self
        }
        
        /// Add request modifiers.
        ///
        /// - Parameter modifiers: A Sequence of request modifiers.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add<S>(modifiers: S) -> Self where
            S: Sequence, S.Iterator.Element == Modifier
        {
            request.pModifiers.append(contentsOf: modifiers)
            return self
        }
        
        /// Set the request modifiers.
        ///
        /// - Parameter modifiers: A Sequence of Modifier.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(modifiers: S) -> Self where
            S: Sequence, S.Iterator.Element == Modifier
        {
            request.pModifiers.removeAll()
            return self.add(modifiers: modifiers)
        }
        
        /// Add a request modifier.
        ///
        /// - Parameter modifier: A Modifier instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(modifier: Modifier) -> Self {
            request.pModifiers.append(modifier)
            return self
        }
    }
}

extension HMCDTextSearchRequest.Builder: HMBuilderType {
    public typealias Buildable = HMCDTextSearchRequest
    
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(key: buildable.pKey)
                .with(value: buildable.pValue)
                .with(comparison: buildable.pComparison)
                .with(modifiers: buildable.pModifiers)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return request
    }
}
