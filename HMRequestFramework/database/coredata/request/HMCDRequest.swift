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
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        nsSortDescriptors = []
        cdDataToSave = []
        retryCount = 1
        middlewaresEnabled = false
    }
}

extension HMCDRequest: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: HMCDRequest
        
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
    }
}

extension HMCDRequest: HMProtocolConvertibleType {
    public typealias PTCType = HMCDRequestType
    
    public func asProtocol() -> PTCType {
        return self as PTCType
    }
}

extension HMCDRequest.Builder: HMProtocolConvertibleBuilderType {
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter generic: A HMCDRequestType instance.
    /// - Returns: The current Builder instance.
    public func with(generic: Buildable.PTCType) -> Buildable.Builder {
        return self
            .with(operation: try? generic.operation())
            .with(entityName: try? generic.entityName())
            .with(predicate: try? generic.predicate())
            .with(sortDescriptors: try? generic.sortDescriptors())
            .with(dataToSave: try? generic.dataToSave())
            .with(retries: generic.retries())
            .with(applyMiddlewares: generic.applyMiddlewares())
            .with(requestDescription: generic.requestDescription())
    }
}

extension HMCDRequest.Builder: HMRequestBuilderType {
    public typealias Buildable = HMCDRequest
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter retries: An Int value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(retries: Int) -> Buildable.Builder {
        request.retryCount = retries
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter applyMiddlewares: A Bool value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(applyMiddlewares: Bool) -> Buildable.Builder {
        request.middlewaresEnabled = applyMiddlewares
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter requestDescription: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(requestDescription: String?) -> Buildable.Builder {
        request.rqDescription = requestDescription
        return self
    }

    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Buildable.Builder {
        return with(generic: buildable)
    }
    
    public func build() -> Buildable {
        return request
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
    
    public func requestDescription() -> String? {
        return rqDescription
    }
}

extension HMCDRequest: CustomStringConvertible {
    public var description: String {
        var ops: String
        
        if let operation = try? self.operation() {
            ops = String(describing: operation)
            
            if
                case .fetch = operation,
                let predicate = try? self.predicate(),
                let sorts = try? self.sortDescriptors()
            {
                ops = "\(ops) with predicate \(predicate) and sort \(sorts)"
            }
        } else {
            ops = "INVALID OPERATION"
        }
        
        let description = self.requestDescription() ?? "NONE"
        return "Performing \(ops). Description: \(description)"
    }
}

