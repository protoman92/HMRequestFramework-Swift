//
//  ErrorCDManager.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 25/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities
import SwiftUtilitiesTests
@testable import HMRequestFramework

/// Throw errors all over the place.
public final class ErrorCDManager: HMCDManager {
    public static let fetchError = "Fetch error"
    public static let saveToFileError = "Save to file error"
    
    public var fetchSuccess: () -> Bool
    public var saveToFileSuccess: () -> Bool
    
    public required init(constructor: HMCDConstructorType) throws {
        fetchSuccess = {true}
        saveToFileSuccess = {true}
        try super.init(constructor: constructor)
    }
    
    override public func blockingFetch<Val>(_ request: NSFetchRequest<Val>) throws -> [Val] {
        if fetchSuccess() {
            return try super.blockingFetch(request)
        } else {
            throw Exception(ErrorCDManager.fetchError)
        }
    }
    
    override public func persistChangesToFileUnsafely() throws {
        if saveToFileSuccess() {
            try super.persistChangesToFileUnsafely()
        } else {
            throw Exception(ErrorCDManager.saveToFileError)
        }
    }
}
