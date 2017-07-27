//
//  HMPersistentStoreSettings.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this class to provide settings when we add persistent stores.
public struct HMPersistentStoreSettings {
    /// This enum details available store types.
    ///
    /// - SQLite: SQLite store type.
    public enum StoreType {
        case InMemory
        case SQLite
        
        /// Get the store type.
        ///
        /// - Returns: A String value.
        public func storeType() -> String {
            switch self {
            case .InMemory:
                return NSInMemoryStoreType
                
            case .SQLite:
                return NSSQLiteStoreType
            }
        }
    }
    
    /// This enum details available store options.
    ///
    /// - migrateStoreAutomatically: Migrate store automatically.
    /// - inferMappingAutomatically: Infer mapping automatically.
    public enum StoreOption {
        case migrateStoreAutomatically
        case inferMappingAutomatically
        
        /// Get the option type.
        ///
        /// - Returns: A String value.
        public func optionType() -> String {
            switch self {
            case .migrateStoreAutomatically:
                return NSMigratePersistentStoresAutomaticallyOption
                
            case .inferMappingAutomatically:
                return NSInferMappingModelAutomaticallyOption
            }
        }
    }
    
    fileprivate var cdStoreType: String?
    fileprivate var cdOptions: [AnyHashable : Any]
    fileprivate var configName: String?
    fileprivate var psStoreURL: URL?
    
    fileprivate init() {
        cdOptions = [:]
    }
    
    public func storeType() throws -> String {
        if let storeType = cdStoreType {
            return storeType
        } else {
            throw Exception("Store type cannot be nil")
        }
    }
    
    public func configurationName() throws -> String? {
        return configName
    }
    
    public func persistentStoreURL() throws -> URL? {
        return psStoreURL
    }
    
    public func options() throws -> [AnyHashable : Any]? {
        return cdOptions.isEmpty ? nil : cdOptions
    }
}

public extension HMPersistentStoreSettings {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        private var settings: HMPersistentStoreSettings
        
        fileprivate init() {
            settings = HMPersistentStoreSettings()
        }
        
        /// Set the store type using a StoreType instance.
        ///
        /// - Parameter storeType: A StoreType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(storeType: StoreType) -> Builder {
            settings.cdStoreType = storeType.storeType()
            return self
        }
        
        /// Set the persistent store URL.
        ///
        /// - Parameter url: A URL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(persistentStoreURL url: URL) -> Builder {
            settings.psStoreURL = url
            return self
        }
        
        /// Set the persistent store URL using a HMPersistentStoreURL instance.
        ///
        /// - Parameter url: A HMPersistentStoreURL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(persistentStoreURL url: HMPersistentStoreURL) -> Builder {
            return (try? with(persistentStoreURL: url.storeURL())) ?? self
        }
        
        /// Set the store options.
        ///
        /// - Parameter options: A Dictionary of options.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(options: [AnyHashable : Any]) -> Builder {
            settings.cdOptions = options
            return self
        }
        
        /// Add an option to store options.
        ///
        /// - Parameters:
        ///   - option: The option key.
        ///   - value: The option value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(option: AnyHashable, with value: Any) -> Builder {
            settings.cdOptions[option] = value
            return self
        }
        
        /// Set the store option with a value.
        ///
        /// - Parameters:
        ///   - option: A StoreOption instance.
        ///   - value: The option value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(option: StoreOption, with value: Any) -> Builder {
            return add(option: option.optionType(), with: value)
        }
        
        public func build() -> HMPersistentStoreSettings {
            return settings
        }
    }
}


