//
//  HMCDBlockPerformerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

public enum ContextPerformanceStrategy: EnumerableType {
    case perform
    case performAndWait
    
    public static func allValues() -> [ContextPerformanceStrategy] {
        return [.perform, .performAndWait]
    }
}

/// Classes that implement this protocol must be able to perform some code
/// block on the context's thread.
public protocol HMCDBlockPerformerType {}

public extension HMCDBlockPerformerType {
    
    /// Perform some block using the context's thread.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - strategy: A ContextPerformanceStrategy instance.
    ///   - block: A closure block.
    public func performOnContextThread(_ context: NSManagedObjectContext,
                                       _ strategy: ContextPerformanceStrategy,
                                       _ block: @escaping () -> Void) {
        switch strategy {
        case .perform:
            context.perform(block)
            
        case .performAndWait:
            context.performAndWait(block)
        }
    }
    
    /// Perform some block using the context's thread using a default strategy.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - block: A closure block.
    public func performOnContextThread(_ context: NSManagedObjectContext,
                                       _ block: @escaping () -> Void) {
        performOnContextThread(context, .perform, block)
    }
}
