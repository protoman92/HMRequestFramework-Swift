//
//  HMCDStoreSettings.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this class to provide settings when we add persistent stores.
public struct HMCDStoreSettings {
    /// This enum details available store types.
    ///
    /// - SQLite: SQLite store type.
    public enum StoreType: EnumerableType {
        case InMemory
        case SQLite
        
        public static func allValues() -> [StoreType] {
            return [.InMemory, .SQLite]
        }
        
        public static func from(type: String) -> StoreType? {
            return allValues().first(where: {$0.storeType() == type})
        }
        
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
    
    public func configurationName() -> String? {
        return configName
    }
    
    public func persistentStoreURL() -> URL? {
        return psStoreURL
    }
    
    public func options() -> [AnyHashable : Any]? {
        return cdOptions.isEmpty ? nil : cdOptions
    }
}

extension HMCDStoreSettings: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var settings: Buildable
        
        fileprivate init() {
            settings = Buildable()
        }
        
        /// Set the store type using a StoreType instance.
        ///
        /// - Parameter storeType: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(storeType: String?) -> Self {
            settings.cdStoreType = storeType
            return self
        }
        
        /// Set the store type using a StoreType instance.
        ///
        /// - Parameter storeType: A StoreType instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(storeType: StoreType) -> Self {
            settings.cdStoreType = storeType.storeType()
            return self
        }
        
        /// Set the persistent store URL.
        ///
        /// - Parameter url: A URL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(persistentStoreURL url: URL?) -> Self {
            settings.psStoreURL = url
            return self
        }
        
        /// Set the persistent store URL using a HMPersistentStoreURL instance.
        ///
        /// - Parameter url: A HMPersistentStoreURL instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(persistentStoreURL url: HMCDStoreURL) -> Self {
            return with(persistentStoreURL: try? url.storeURL())
        }
        
        /// Set the store options.
        ///
        /// - Parameter options: A Dictionary of options.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(options: [AnyHashable : Any]) -> Self {
            settings.cdOptions = options
            return self
        }
        
        /// Set the config name.
        ///
        /// - Parameter configName: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(configName: String?) -> Self {
            settings.configName = configName
            return self
        }
        
        /// Add an option to store options.
        ///
        /// - Parameters:
        ///   - option: The option key.
        ///   - value: The option value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func add(option: AnyHashable, with value: Any) -> Self {
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
        public func add(option: StoreOption, with value: Any) -> Self {
            return add(option: option.optionType(), with: value)
        }
    }
}

extension HMCDStoreSettings.Builder: HMBuilderType {
    public typealias Buildable = HMCDStoreSettings
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    public func with(buildable: Buildable) -> Self {
        return self
            .with(storeType: buildable.cdStoreType)
            .with(options: buildable.options() ?? [:])
            .with(configName: buildable.configurationName())
            .with(persistentStoreURL: buildable.persistentStoreURL())
    }
    
    public func build() -> Buildable {
        return settings
    }
}
