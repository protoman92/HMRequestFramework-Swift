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
    fileprivate var cdStoreSettings: [HMCDStoreSettings]
    fileprivate var cdMainContextMode: HMCDMainContextMode
    
    fileprivate init() {
        cdStoreSettings = []
        cdMainContextMode = .mainThread
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
    public func storeSettings() throws -> [HMCDStoreSettings] {
        return cdStoreSettings
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Returns: A HMCDMainContextMode instance.
    public func mainContextMode() -> HMCDMainContextMode {
        return cdMainContextMode
    }
}

extension HMCDConstructor: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var constructor: Buildable
        
        fileprivate init() {
            constructor = Buildable()
        }
        
        /// Set the objectModl.
        ///
        /// - Parameter objectModel: A NSManagedObjectModel instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(objectModel: NSManagedObjectModel?) -> Self {
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
            -> Self
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
        /// - Parameters:
        ///   - modelName: A String value.
        ///   - cls: Any class object.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(modelName: String, for cls: AnyClass) -> Self {
            let bundle = Bundle(for: cls)
            
            if let modelURL = bundle.url(forResource: modelName, withExtension: "momd") {
                return with(objectModel: NSManagedObjectModel(contentsOf: modelURL))
            } else {
                return self
            }
        }
        
        /// Set the objectModel using a Sequence of HMCDObjectType classes.
        ///
        /// - Parameter cdTypes: An Sequence of HMCDObjectType subtype.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(cdTypes: S) -> Self where
            S: Sequence, S.Iterator.Element == HMCDObjectType.Type
        {
            do {
                let model = NSManagedObjectModel()
                model.entities = try cdTypes.map({try $0.entityDescription()})
                return with(objectModel: model)
            } catch {
                return self
            }
        }
        
        /// Set the objectModel using a varargs of HMCDObjectType classes.
        ///
        /// - Parameter cdTypes: A varargs of HMCDObjectType subtype.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(cdTypes: HMCDObjectType.Type...) -> Self {
            return with(cdTypes: cdTypes.map({$0}))
        }
        
        /// Set the store settings using a Sequence of HMPersistentStoreSettings.
        ///
        /// - Parameter settings: A Sequence of HMPersistentStoreSettings.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(settings: S?) -> Self where
            S: Sequence, S.Iterator.Element == HMCDStoreSettings
        {
            if let settings = settings {
                constructor.cdStoreSettings.append(contentsOf: settings)
            }
            
            return self
        }
        
        /// Set the main context mode.
        ///
        /// - Parameter mainContextMode: A HMCDMainContextMode instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(mainContextMode: HMCDMainContextMode) -> Self {
            constructor.cdMainContextMode = mainContextMode
            return self
        }
    }
}

extension HMCDConstructor.Builder: HMBuilderType {
    public typealias Buildable = HMCDConstructor
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(objectModel: try? buildable.objectModel())
                .with(settings: (try? buildable.storeSettings()))
                .with(mainContextMode: buildable.mainContextMode())
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return constructor
    }
}
