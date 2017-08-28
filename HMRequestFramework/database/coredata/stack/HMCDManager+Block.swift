//
//  HMCDManager+Block.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 28/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Classes that implement this protocol must be able to perform some actions
/// on a queue.
public protocol HMCDBlockPerformerType: class {
    func perform(_ block: @escaping () -> Void)
    
    // In XCode8, the performAndWait block escapes, so we need this for cross-XCode
    // compatibility.
    func performEscapingBlockAndWait(_ block: @escaping () -> Void)
}

extension NSManagedObjectContext: HMCDBlockPerformerType {
    public func performEscapingBlockAndWait(_ block: @escaping () -> Void) {
        self.performAndWait(block)
    }
}

extension NSPersistentStoreCoordinator: HMCDBlockPerformerType {
    public func performEscapingBlockAndWait(_ block: @escaping () -> Void) {
        self.performAndWait(block)
    }
}

public enum BlockPerformaStrategy: EnumerableType {
    case perform
    case performAndWait
    
    public static func allValues() -> [BlockPerformaStrategy] {
        return [.perform, .performAndWait]
    }
}

public extension HMCDManager {
    
    /// Perform some block using the context's thread.
    ///
    /// - Parameters:
    ///   - performer: A HMCDBlockPerformerType instance.
    ///   - strategy: A ContextPerformanceStrategy instance.
    ///   - block: A closure block.
    public func performOnQueue(_ performer: HMCDBlockPerformerType,
                               _ strategy: BlockPerformaStrategy,
                               _ block: @escaping () -> Void) {
        switch strategy {
        case .perform:
            performer.perform(block)
            
        case .performAndWait:
            performer.performEscapingBlockAndWait(block)
        }
    }
    
    /// Perform some block using the context's thread using a default strategy.
    ///
    /// - Parameters:
    ///   - context: A HMCDBlockPerformerType instance.
    ///   - block: A closure block.
    public func performOnQueue(_ performer: HMCDBlockPerformerType,
                               _ block: @escaping () -> Void) {
        performOnQueue(performer, .perform, block)
    }
    
    /// Serialize some operations.
    ///
    /// - Parameter block: A closure block.
    public func serializeBlock(_ block: @escaping () -> Void) {
        performOnQueue(mainObjectContext(), block)
    }
}
