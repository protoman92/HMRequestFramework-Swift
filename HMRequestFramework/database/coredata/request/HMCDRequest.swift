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
    
    fileprivate init() {
        nsSortDescriptors = []
        cdDataToSave = []
        retryCount = 1
    }
}

public extension HMCDRequest {
    public static func builder() -> Builder {
        return Builder()
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
        public func with(entityName: String) -> Builder {
            request.cdEntityName = entityName
            return self
        }
        
        /// Set the entityName using a HMCDRepresentableType subtype.
        ///
        /// - Parameter representable: A HMCDRepresentableType class.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<CDR>(representable: CDR.Type) -> Builder where CDR: HMCDRepresentableType {
            return (try? with(entityName: representable.entityName())) ?? self
        }
        
        /// Set the predicate.
        ///
        /// - Parameter predicate: A NSPredicate instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(predicate: NSPredicate) -> Builder {
            request.nsPredicate = predicate
            return self
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: A Sequence of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(sortDescriptors: S) -> Builder
            where S: Sequence, S.Iterator.Element == NSSortDescriptor
        {
            request.nsSortDescriptors.append(contentsOf: sortDescriptors)
            return self
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: A Sequence of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(sortDescriptors: S) -> Builder
            where S: Sequence, S.Iterator.Element: NSSortDescriptor
        {
            return with(sortDescriptors: sortDescriptors.map(eq))
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
        public func with(operation: CoreDataOperation) -> Builder {
            request.cdOperation = operation
            return self
        }
        
        /// Set the data to save.
        ///
        /// - Parameter data: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToSave data: S) -> Builder where
            S: Sequence, S.Iterator.Element == NSManagedObject
        {
            request.cdDataToSave.append(contentsOf: data)
            return self
        }
        
        /// Set the data to save.
        ///
        /// - Parameter data: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToSave data: S) -> Builder where
            S: Sequence, S.Iterator.Element: NSManagedObject
        {
            return with(dataToSave: data.map({$0 as NSManagedObject}))
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
        
        if case .persistData = operation, data.isEmpty {
            throw Exception("Data to save cannot be nil or empty")
        } else {
            return data
        }
    }
    
    public func retries() -> Int {
        return Swift.max(retryCount, 1)
    }
}
