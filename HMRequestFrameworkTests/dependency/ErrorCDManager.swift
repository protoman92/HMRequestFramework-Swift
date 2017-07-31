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
    public static let saveDataToFileError = "Save data to file error"
    
    public var fetchSuccess: () -> Bool
    public var saveToFileSuccess: () -> Bool
    public var saveDataToFileSuccess: () -> Bool
    
    public required init(constructor: HMCDConstructorType) throws {
        fetchSuccess = {true}
        saveToFileSuccess = {true}
        saveDataToFileSuccess = {true}
        try super.init(constructor: constructor)
    }
    
    override public func blockingFetch<Val>(_ request: NSFetchRequest<Val>) throws -> [Val] {
        if fetchSuccess() {
            return try super.blockingFetch(request)
        } else {
            throw Exception(ErrorCDManager.fetchError)
        }
    }
    
    override public func saveToFileUnsafely() throws {
        if saveToFileSuccess() {
            try super.saveToFileUnsafely()
        } else {
            throw Exception(ErrorCDManager.saveToFileError)
        }
    }
    
    override public func saveToFileUnsafely<S>(_ data: S) throws where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        if saveDataToFileSuccess() {
            try super.saveToFileUnsafely(data)
        } else {
            throw Exception(ErrorCDManager.saveDataToFileError)
        }
    }
}
