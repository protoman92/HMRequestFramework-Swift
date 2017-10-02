//
//  HMCDResultControllerDelegate.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 2/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this class to receive CoreData FRC events.
public final class HMCDResultControllerDelegate: NSObject {
    public typealias DBEvent = HMCDEvent<Any>
    public typealias Result = NSFetchRequestResult
    
    public typealias ChangeType = NSFetchedResultsChangeType
    public typealias Controller = NSFetchedResultsController<Result>
    public typealias SectionInfo = NSFetchedResultsSectionInfo
    
    public typealias DidChangeContent = (Controller) -> Void
    public typealias WillChangeContent = (Controller) -> Void
    public typealias DidChangeObject = (Controller, Any, IndexPath?, ChangeType, IndexPath?) -> Void
    public typealias DidChangeSection = (Controller, SectionInfo, Int, ChangeType) -> Void
    
    fileprivate let operation: OperationQueue
    fileprivate var didChangeContent: DidChangeContent?
    fileprivate var willChangeContent: WillChangeContent?
    fileprivate var didChangeObject: DidChangeObject?
    fileprivate var didChangeSection: DidChangeSection?
    
    deinit {
        // Make sure references are properly disposed of.
        debugPrint("Deinit \(self)")
    }
    
    fileprivate override init() {
        let operation = OperationQueue()
        operation.underlyingQueue = DispatchQueue.main
        self.operation = operation
    }
    
    public func removeCallbacks() {
        didChangeContent = nil
        willChangeContent = nil
        didChangeObject = nil
        didChangeSection = nil
    }
}

extension HMCDResultControllerDelegate: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var delegate: Buildable
        
        fileprivate init() {
            delegate = Buildable()
        }
        
        /// Set willChangeContent.
        ///
        /// - Parameter willChangeContent: A WillChangeContent instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(willChangeContent: WillChangeContent?) -> Self {
            delegate.willChangeContent = willChangeContent
            return self
        }
        
        /// Set didChangeContent.
        ///
        /// - Parameter didChangeContent: A DidChangeContent instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didChangeContent: DidChangeContent?) -> Self {
            delegate.didChangeContent = didChangeContent
            return self
        }
        
        /// Set didChangeObject.
        ///
        /// - Parameter didChangeObject: A DidChangeObject instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didChangeObject: DidChangeObject?) -> Self {
            delegate.didChangeObject = didChangeObject
            return self
        }
        
        /// Set didChangeSection.
        ///
        /// - Parameter didChangeSection: A DidChangeSection instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didChangeSection: DidChangeSection?) -> Self {
            delegate.didChangeSection = didChangeSection
            return self
        }
    }
}

extension HMCDResultControllerDelegate.Builder: HMBuilderType {
    public typealias Buildable = HMCDResultControllerDelegate
    
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(willChangeContent: buildable.willChangeContent)
                .with(didChangeContent: buildable.didChangeContent)
                .with(didChangeObject: buildable.didChangeObject)
                .with(didChangeSection: buildable.didChangeSection)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return delegate
    }
}

extension HMCDResultControllerDelegate: NSFetchedResultsControllerDelegate {
    
    /// Notifies the delegate that all section and object changes have been sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view. Providing an empty implementation will
    /// enable change tracking if you do not care about the individual callbacks.
    public func controllerDidChangeContent(_ controller: Controller) {
        operation.addOperation({[weak self] in
            self?.didChangeContent?(controller)
        })
    }
    
    /// Notifies the delegate that section and object changes are about to be
    /// processed and notifications will be sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view.
    public func controllerWillChangeContent(_ controller: Controller) {
        operation.addOperation({[weak self] in
            self?.willChangeContent?(controller)
        })
    }
    
    /// Asks the delegate to return the corresponding section index entry for a
    /// given section name.
    ///
    /// Does not enable NSFetchedResultsController change tracking.
    ///
    /// If this method isn't implemented by the delegate, the default implementation
    /// returns the capitalized first letter of the section name
    /// (see NSFetchedResultsController sectionIndexTitleForSectionName:)
    ///
    /// Only needed if a section index is used.
    public func controller(
        _ controller: Controller,
        sectionIndexTitleForSectionName sectionName: String) -> String?
    {
        return nil
    }
    
    /// Notifies the delegate that a fetched object has been changed due to an
    /// add, remove, move, or update. Enables NSFetchedResultsController change
    /// tracking.
    ///
    /// Inserts and Deletes are reported when an object is created, destroyed,
    /// or changed in such a way that changes whether it matches the fetch request's
    /// predicate. Only the Inserted/Deleted object is reported; like inserting/
    /// deleting from an array, it's assumed that all objects that come after the
    /// affected object shift appropriately.
    ///
    /// Move is reported when an object changes in a manner that affects its position
    /// in the results.  An update of the object is assumed in this case, no separate
    /// update message is sent to the delegate.
    ///
    /// Update is reported when an object's state changes, and the changes do not
    /// affect the object's position in the results.
    ///
    /// - Parameters:
    ///   - controller: Controller instance that noticed the change on its fetched objects
    ///   - anObject: Changed object
    ///   - indexPath: IndexPath of changed object (nil for inserts)
    ///   - type: Indicates if the change was an insert, delete, move, or update
    ///   - newIndexPath: The destination path of changed object (nil for deletes)
    public func controller(_ controller: Controller,
                           didChange anObject: Any,
                           at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
        operation.addOperation({[weak self] in
            self?.didChangeObject?(controller, anObject, indexPath, type, newIndexPath)
        })
    }
    
    /// Notifies the delegate of added or removed sections.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Changes on section info are reported before changes on fetchedObjects.
    ///
    /// - Parameters:
    ///   - controller: Controller instance that noticed the change on its sections.
    ///   - sectionInfo: Changed section.
    ///   - sectionIndex: Index of changed section.
    ///   - type: Indicates if the change was an insert or delete.
    public func controller(_ controller: Controller,
                           didChange sectionInfo: NSFetchedResultsSectionInfo,
                           atSectionIndex sectionIndex: Int,
                           for type: NSFetchedResultsChangeType) {
        operation.addOperation({[weak self] in
            self?.didChangeSection?(controller, sectionInfo, sectionIndex, type)
        })
    }
}
