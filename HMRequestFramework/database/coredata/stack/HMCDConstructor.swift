//
//  HMCDFileConstructor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// CoreData dependency constructor that uses a file.
public struct HMCDConstructor {
    fileprivate var cdObjectModel: NSManagedObjectModel?
    fileprivate var cdStoreSettings: [HMPersistentStoreSettings]
    
    fileprivate init() {
        cdStoreSettings = []
    }
}

extension HMCDConstructor: HMCDConstructorType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A NSManagedObjectModel instance.
    /// - Throws: Exception if the model cannot be created.
    public func objectModel() throws -> NSManagedObjectModel {
        if let model = cdObjectModel {
            return model
        } else {
            throw Exception("Object model cannot be nil")
        }
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: An Array of HMPersistentStoreSettings.
    /// - Throws: Exception if the settings are not available.
    public func storeSettings() throws -> [HMPersistentStoreSettings] {
        return cdStoreSettings
    }
}

public extension HMCDConstructor {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        private var constructor: HMCDConstructor
        
        fileprivate init() {
            constructor = HMCDConstructor()
        }
        
        /// Set the objectModl.
        ///
        /// - Parameter objectModel: A NSManagedObjectModel instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(objectModel: NSManagedObjectModel) -> Builder {
            constructor.cdObjectModel = objectModel
            return self
        }
        
        /// Set the objectModel based on bundles and metadata.
        ///
        /// - Parameters:
        ///   - bundles: An Array of Bundle.
        ///   - metadata: A Dictionary of metadata.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(mergedModelFrom bundles: [Bundle]?,
                         withMetadata metadata: [String : Any]?)
            -> Builder
        {
            let model: NSManagedObjectModel?
            
            if let metadata = metadata {
                model = .mergedModel(from: bundles, forStoreMetadata: metadata)
            } else {
                model = .mergedModel(from: bundles)
            }
            
            if let model = model {
                return with(objectModel: model)
            } else {
                return self
            }
        }
        
        /// Set the objectModel from a model name.
        ///
        /// - Parameter modelName: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(modelName: String) -> Builder {
            let bundle = Bundle(for: HMCDManager.self)
            
            if
                let modelURL = bundle.url(forResource: modelName, withExtension: "momd"),
                let model = NSManagedObjectModel(contentsOf: modelURL)
            {
                return with(objectModel: model)
            } else {
                return self
            }
        }
        
        /// Set the objectModel using a Sequence of HMCDRepresentableType
        /// classes.
        ///
        /// - Parameter representables: An Sequence of HMCDRepresentableType subtype.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(representables: S) -> Builder where
            S: Sequence, S.Iterator.Element == HMCDRepresentableType.Type
        {
            do {
                let model = NSManagedObjectModel()
                model.entities = try representables.map({try $0.entityDescription()})
                return with(objectModel: model)
            } catch {
                return self
            }
        }
        
        /// Set the objectModel using a varargs of HMCDRepresentableType classes.
        ///
        /// - Parameter representables: A varargs of HMCDRepresentableType subtype.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(representables: HMCDRepresentableType.Type...) -> Builder {
            return with(representables: representables.map(eq))
        }
        
        /// Set the store settings using a Sequence of HMPersistentStoreSettings.
        ///
        /// - Parameter settings: A Sequence of HMPersistentStoreSettings.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(settings: S) -> Builder where
            S: Sequence, S.Iterator.Element == HMPersistentStoreSettings
        {
            constructor.cdStoreSettings.append(contentsOf: settings)
            return self
        }
        
        public func build() -> HMCDConstructor {
            return constructor
        }
    }
}
