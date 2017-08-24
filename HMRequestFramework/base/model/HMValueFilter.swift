//
//  HMValueFilter.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

/// Classes that implement this protocol must be able to filter out some
/// filterables based on another object.
public struct HMValueFilter<Value: HMValueFilterableType> {
    public typealias Filterable = Value.Filterable
    public typealias Filter = (Value, Filterable) throws -> Bool
    
    private let filterFn: Filter
    
    public init(_ filterFn: @escaping Filter) {
        self.filterFn = filterFn
    }
    
    /// Filter values using a filter function.
    ///
    /// - Parameters:
    ///   - value: A Value instance.
    ///   - filterable: A Filterable instance.
    /// - Returns: A Bool value.
    /// - Throws: Exception if the operation fails.
    public func filter(_ value: Value, _ filterable: Filterable) throws -> Bool {
        return try filterFn(value, filterable)
    }
}
