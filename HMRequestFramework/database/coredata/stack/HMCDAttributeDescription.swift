//
//  HMCDAttributeDescription.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 26/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData

public extension NSAttributeDescription {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        private let attribute: NSAttributeDescription
        
        fileprivate init() {
            attribute = NSAttributeDescription()
        }
        
        /// Set the attribute name.
        ///
        /// - Parameter name: A String value.
        /// - Returns: The current Builder instance.
        public func with(name: String) -> Self {
            attribute.name = name
            return self
        }
        
        /// Set the attribute type.
        ///
        /// - Parameter type: An AttributeType instance.
        /// - Returns: The current Builder instance.
        public func with(type: NSAttributeType) -> Self {
            attribute.attributeType = type
            return self
        }
        
        /// Set the optional flag.
        ///
        /// - Parameter optional: A Bool value.
        /// - Returns: The current Builder instance.
        public func with(optional: Bool) -> Self {
            attribute.isOptional = optional
            return self
        }
        
        /// Set the optional flag.
        ///
        /// - Returns: The current Builder instance.
        public func shouldBeOptional() -> Self {
            return with(optional: true)
        }
        
        /// Set the optional flag.
        ///
        /// - Returns: The current Builder instance.
        public func shouldNotBeOptional() -> Self {
            return with(optional: false)
        }
        
        /// Set the allowsExternalBinaryDataStorage flag.
        ///
        /// - Parameter allow: A Bool value.
        /// - Returns: The current Builder instance.
        public func with(allowExternalBinaryDataStorage allow: Bool) -> Self {
            attribute.allowsExternalBinaryDataStorage = allow
            return self
        }
        
        /// Set the allowsExternalBinaryDataStorage flag.
        ///
        /// - Parameter allow: A Bool value.
        /// - Returns: The current Builder instance.
        public func shouldAllowExternalBinaryDataStorage() -> Self {
            return with(allowExternalBinaryDataStorage: true)
        }
        
        /// Set the allowsExternalBinaryDataStorage flag.
        ///
        /// - Parameter allow: A Bool value.
        /// - Returns: The current Builder instance.
        public func shouldNotAllowExternalBinaryDataStorage() -> Self {
            return with(allowExternalBinaryDataStorage: false)
        }
        
        /// Set the default value.
        ///
        /// - Parameter defaultValue: Any object.
        /// - Returns: The current Builder instance.
        public func with(defaultValue: Any?) -> Builder {
            attribute.defaultValue = defaultValue
            return self
        }
        
        /// Set the attributeValueClassName.
        ///
        /// - Parameter cls: A String value.
        /// - Returns: The current Builder instance.
        public func with(attributeValueClassName cls: String?) -> Self {
            attribute.attributeValueClassName = cls
            return self
        }
        
        /// Set the valueTransformerName.
        ///
        /// - Parameter cls: A String value.
        /// - Returns: The current Builder instance.
        public func with(valueTransformerName name: String?) -> Self {
            attribute.valueTransformerName = name
            return self
        }
        
        public func build() -> NSAttributeDescription {
            return attribute
        }
    }
}
