//
//  HMCDOperationMode.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 6/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Determine how a CoreData operation should be executed.
///
/// - queued: Queue the operation with the main context's internal queue.
/// - unqueued: Execute without queueing at the risk of invalid data if used
///             in a multithreaded environment. This mode is generally inadvisable.
public enum HMCDOperationMode {
    case queued
    case unqueued
}
