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
    fileprivate var cdContextToSave: NSManagedObjectContext?
    fileprivate var cdDataToDelete: [NSManagedObject]
    fileprivate var retryCount: Int
    fileprivate var middlewaresEnabled: Bool
    fileprivate var rqDescription: String?
    
    fileprivate init() {
        nsSortDescriptors = []
        cdDataToDelete = []
        retryCount = 1
        middlewaresEnabled = false
    }
}

extension HMCDRequest: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var request: Buildable
        
        fileprivate init() {
            request = Buildable()
        }
        
        /// Set the entity name.
        ///
        /// - Parameter entityName: A String value.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(entityName: String?) -> Self {
            request.cdEntityName = entityName
            return self
        }
        
        /// Set the entityName using a HMCDRepresentableType subtype.
        ///
        /// - Parameter representable: A HMCDRepresentableType class type.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<CDR>(representable: CDR.Type) -> Self where CDR: HMCDRepresentableType {
            return with(entityName: try? representable.entityName())
        }
        
        /// Set the entityName using a HMCDPureObjectType subtype.
        ///
        /// - Parameter pureObject: A HMCDPureObjectType class type.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<PO>(pureObject: PO.Type) -> Self where PO: HMCDPureObjectType {
            return with(representable: pureObject.CDClass.self)
        }
        
        /// Set the predicate.
        ///
        /// - Parameter predicate: A NSPredicate instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(predicate: NSPredicate?) -> Self {
            request.nsPredicate = predicate
            return self
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: A Sequence of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(sortDescriptors: S?) -> Self where
            S: Sequence, S.Iterator.Element == NSSortDescriptor
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
        public func with<S>(sortDescriptors: S?) -> Self where
            S: Sequence, S.Iterator.Element: NSSortDescriptor
        {
            return with(sortDescriptors: sortDescriptors?.map(eq))
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: Varargs of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(sortDescriptors: NSSortDescriptor...) -> Self {
            return with(sortDescriptors: sortDescriptors.map(eq))
        }
        
        /// Set the sort descriptors.
        ///
        /// - Parameter sortDescriptors: Varargs of NSSortDescriptor.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<SD>(sortDescriptors: SD...) -> Self where SD: NSSortDescriptor {
            return with(sortDescriptors: sortDescriptors.map(eq))
        }
        
        /// Set the operation.
        ///
        /// - Parameter operation: A CoreDataOperation instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(operation: CoreDataOperation?) -> Self {
            request.cdOperation = operation
            return self
        }
        
        /// Set the context to save.
        ///
        /// - Parameter data: A NSManagedObject instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(contextToSave: NSManagedObjectContext?) -> Self {
            request.cdContextToSave = contextToSave
            return self
        }
        
        /// Set the data to delete.
        ///
        /// - Parameter dataToDelete: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToDelete: S?) -> Self where
            S: Sequence, S.Iterator.Element == NSManagedObject
        {
            if let data = dataToDelete {
                request.cdDataToDelete.append(contentsOf: data)
            }
            
            return self
        }
        
        /// Set the data to delete.
        ///
        /// - Parameter dataToDelete: A Sequence of NSManagedObject.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with<S>(dataToDelete: S?) -> Self where
            S: Sequence, S.Iterator.Element: NSManagedObject
        {
            return with(dataToDelete: dataToDelete?.map({$0 as NSManagedObject}))
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
    @discardableResult
    public func with(generic: Buildable.PTCType) -> Self {
        return self
            .with(operation: try? generic.operation())
            .with(entityName: try? generic.entityName())
            .with(predicate: try? generic.predicate())
            .with(sortDescriptors: try? generic.sortDescriptors())
            .with(contextToSave: try? generic.contextToSave())
            .with(dataToDelete: try? generic.dataToDelete())
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
    public func with(retries: Int) -> Self {
        request.retryCount = retries
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter applyMiddlewares: A Bool value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(applyMiddlewares: Bool) -> Self {
        request.middlewaresEnabled = applyMiddlewares
        return self
    }
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter requestDescription: A String value.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(requestDescription: String?) -> Self {
        request.rqDescription = requestDescription
        return self
    }

    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Self {
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
    
    public func contextToSave() throws -> NSManagedObjectContext {
        if let context = cdContextToSave {
            return context
        } else {
            throw Exception("Context to save cannot be nil")
        }
    }
    
    public func dataToDelete() throws -> [NSManagedObject] {
        return cdDataToDelete
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

