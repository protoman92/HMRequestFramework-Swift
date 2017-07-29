//
//  HMCDRequest.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 20/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this struct whenever concrete HMCDRequestType objects are required.
public struct HMCDRequest {
    fileprivate var cdEntityName: String?
    fileprivate var nsPredicate: NSPredicate?
    fileprivate var nsSortDescriptors: [NSSortDescriptor]
    fileprivate var cdOperation: CoreDataOperation?
    fileprivate var cdDataToSave: [NSManagedObject]
    fileprivate var retryCount: Int
    fileprivate var middlewaresEnabled: Bool
    
    fileprivate init() {
        nsSortDescriptors = []
        cdDataToSave = []
        retryCount = 1
        middlewaresEnabled = false
    }
}

public extension HMCDRequest {
    public static func builder() -> Builder {
        return Builder()
    }
    
    /// Instead of defining setters, we expose a Builder instance for a new
    /// request and copy all properties from this request.
    ///
    /// - Returns: A Builder instance.
    public func builder() -> Builder {
        return HMCDRequest.builder().with(request: self)
    }
    
    public final class Builder {
        private var request: HMCDRequest
        
        fileprivate init() {
            request = HMCDRequest()
        }
        
        /// Set the entity name.
        ///
        /// - Parameter entityName: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(entityName: String?) -> Builder {
            request.cdEntityName = entityName
            return self
        }
        
        /// Set the entityName using a HMCDRepresentableType subtype.
        ///
        /// - Parameter representable: A HMCDRepresentableType class.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<CDR>(representable: CDR.Type) -> Builder where CDR: HMCDRepresentableType {
            return with(entityName: try? representable.entityName())
        }
        
        /// Set the predicate.
        ///
        /// - Parameter predicate: A NSPredicate instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(predicate: NSPredicate?) -> Builder {
            request.nsPredicate = predicate
            return self
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: A Sequence of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(sortDescriptors: S?) -> Builder
            where S: Sequence, S.Iterator.Element == NSSortDescriptor
        {
            if let descriptors = sortDescriptors {
                request.nsSortDescriptors.append(contentsOf: descriptors)
            }
            
            return self
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: A Sequence of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(sortDescriptors: S?) -> Builder
            where S: Sequence, S.Iterator.Element: NSSortDescriptor
        {
            return with(sortDescriptors: sortDescriptors?.map(eq))
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: Varargs of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(sortDescriptors: NSSortDescriptor...) -> Builder {
            return with(sortDescriptors: sortDescriptors.map(eq))
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: Varargs of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<SD>(sortDescriptors: SD...) -> Builder where SD: NSSortDescriptor {
            return with(sortDescriptors: sortDescriptors.map(eq))
        }
        
        /// Set the operation.
        ///
        /// - Parameter operation: A CoreDataOperation instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(operation: CoreDataOperation?) -> Builder {
            request.cdOperation = operation
            return self
        }
        
        /// Set the data to save.
        ///
        /// - Parameter data: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToSave data: S?) -> Builder where
            S: Sequence, S.Iterator.Element == NSManagedObject
        {
            if let data = data {
                request.cdDataToSave.append(contentsOf: data)
            }
            
            return self
        }
        
        /// Set the data to save.
        ///
        /// - Parameter data: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToSave data: S?) -> Builder where
            S: Sequence, S.Iterator.Element: NSManagedObject
        {
            return with(dataToSave: data?.map({$0 as NSManagedObject}))
        }
        
        /// Set the retry count.
        ///
        /// - Parameter retries: An Int value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(retries: Int) -> Builder {
            request.retryCount = retries
            return self
        }
        
        /// Enable or disable middlewares.
        ///
        /// - Parameter applyMiddlewares: A Bool value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(applyMiddlewares: Bool) -> Builder {
            request.middlewaresEnabled = applyMiddlewares
            return self
        }
        
        /// Enable middlewares.
        ///
        /// - Returns: The current Builder instance.
        @discardableResult
        public func shouldApplyMiddlewares() -> Builder {
            return with(applyMiddlewares: true)
        }
        
        /// Disable middlewares.
        ///
        /// - Returns: The current Builder instance.
        public func shouldNotApplyMiddlewares() -> Builder {
            return with(applyMiddlewares: false)
        }
        
        /// Copy all properties from another request to the current one.
        ///
        /// - Parameter request: A HMCDRequestType instance.
        /// - Returns: The current Builder instance.
        public func with(request: HMCDRequestType) -> Builder {
            return self
                .with(operation: try? request.operation())
                .with(entityName: try? request.entityName())
                .with(predicate: try? request.predicate())
                .with(sortDescriptors: try? request.sortDescriptors())
                .with(dataToSave: try? request.dataToSave())
                .with(retries: request.retries())
                .with(applyMiddlewares: request.applyMiddlewares())
        }
        
        public func build() -> HMCDRequest {
            return request
        }
    }
}

extension HMCDRequest: HMCDRequestType {
    public typealias Value = NSManagedObject
    
    public func entityName() throws -> String {
        if let entityName = cdEntityName {
            return entityName
        } else {
            throw Exception("Entity name cannot be nil")
        }
    }
    
    public func operation() throws -> CoreDataOperation {
        if let operation = cdOperation {
            return operation
        } else {
            throw Exception("Operation cannot be nil")
        }
    }
    
    public func predicate() throws -> NSPredicate {
        if let predicate = nsPredicate {
            return predicate
        } else {
            throw Exception("Predicate cannot be nil")
        }
    }
    
    public func sortDescriptors() throws -> [NSSortDescriptor] {
        return nsSortDescriptors
    }
    
    public func dataToSave() throws -> [NSManagedObject] {
        let operation = try self.operation()
        let data = cdDataToSave
        
        if case .persist = operation, data.isEmpty {
            throw Exception("Data to save cannot be nil or empty")
        } else {
            return data
        }
    }
    
    public func retries() -> Int {
        return Swift.max(retryCount, 1)
    }
    
    public func applyMiddlewares() -> Bool {
        return middlewaresEnabled
    }
}
