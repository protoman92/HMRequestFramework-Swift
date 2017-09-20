//
//  HMCDStoreURL.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this class to represent components to build a persistent store URL.
public struct HMCDStoreURL {
    fileprivate var fileManager: FileManager?
    fileprivate var searchPath: FileManager.SearchPathDirectory?
    fileprivate var domainMask: FileManager.SearchPathDomainMask?
    fileprivate var fileName: String?
    fileprivate var fileExtension: String?
    
    /// Get the associated store URL.
    ///
    /// - Returns: A URL instance.
    /// - Throws: Exception if the URL cannot be created.
    public func storeURL() throws -> URL {
        guard
            let fileManager = self.fileManager,
            let fileName = self.fileName,
            let fileExtension = self.fileExtension,
            let searchPath = self.searchPath,
            let domainMask = self.domainMask,
            let directoryURL = fileManager.urls(for: searchPath , in: domainMask).first
        else {
            throw Exception("One or more data fields are nil")
        }
        
        let storeName = "\(fileName).\(fileExtension)"
        return directoryURL.appendingPathComponent(storeName)
    }
}

extension HMCDStoreURL: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var storeURL: Buildable
        
        fileprivate init() {
            storeURL = Buildable()
        }
        
        /// Set the fileManager instance.
        ///
        /// - Parameter fileManager: A FileManager instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(fileManager: FileManager?) -> Self {
            storeURL.fileManager = fileManager
            return self
        }
        
        /// Set the default fileManager instance.
        ///
        /// - Returns: The current Builder instance.
        @discardableResult
        public func withDefaultFileManager() -> Self {
            return with(fileManager: .default)
        }
        
        /// Set the searchPath instance.
        ///
        /// - Parameter searchPath: A SearchPathDirectory instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(searchPath: FileManager.SearchPathDirectory?) -> Self {
            storeURL.searchPath = searchPath
            return self
        }
        
        /// Set the document directory.
        ///
        /// - Returns: The current Builder instance.
        @discardableResult
        public func withDocumentDirectory() -> Self {
            return with(searchPath: .documentDirectory)
        }
        
        /// Set the domainMask instance.
        ///
        /// - Parameter domainMask: A SearchPathDomainMask instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(domainMask: FileManager.SearchPathDomainMask?) -> Self {
            storeURL.domainMask = domainMask
            return self
        }
        
        /// Set the userDomainMask.
        ///
        /// - Returns: The current Builder instance.
        @discardableResult
        public func withUserDomainMask() -> Self {
            return with(domainMask: .userDomainMask)
        }
        
        /// Set the file name.
        ///
        /// - Parameter fileName: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(fileName: String?) -> Self {
            storeURL.fileName = fileName
            return self
        }
        
        /// Set the file extension.
        ///
        /// - Parameter fileExtension: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(fileExtension: String?) -> Self {
            storeURL.fileExtension = fileExtension
            return self
        }
        
        /// Set the file extension using a StoreType
        ///
        /// - Parameter storeType: A StoreType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(storeType: HMCDStoreSettings.StoreType) -> Self {
            if let fileExtension = storeType.fileExtension() {
                return with(fileExtension: fileExtension)
            } else {
                return self
            }
        }
    }
}

extension HMCDStoreURL.Builder: HMBuilderType {
    public typealias Buildable = HMCDStoreURL
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(fileManager: buildable.fileManager)
                .with(fileName: buildable.fileName)
                .with(searchPath: buildable.searchPath)
                .with(domainMask: buildable.domainMask)
                .with(fileExtension: buildable.fileExtension)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return storeURL
    }
}

public extension HMCDStoreSettings.StoreType {
    
    /// Get the associated file extension.
    ///
    /// - Returns: A String value.
    public func fileExtension() -> String? {
        switch self {
        case .SQLite:
            return "sqlite"
            
        default:
            return nil
        }
    }
}
