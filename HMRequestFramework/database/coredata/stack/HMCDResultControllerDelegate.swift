//
//  HMCDResultControllerDelegate.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 2/10/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Use this class to receive CoreData FRC events.
public final class HMCDResultControllerDelegate: NSObject {
    public typealias DBEvent = HMCDEvent<Any>
    public typealias Result = NSFetchRequestResult
    
    public typealias ChangeType = NSFetchedResultsChangeType
    public typealias Controller = NSFetchedResultsController<Result>
    public typealias SectionInfo = NSFetchedResultsSectionInfo
    
    fileprivate let observer: AnyObserver<DBEvent>
    
    deinit {
        // Make sure references are properly disposed of.
        debugPrint("Deinit \(self)")
    }
    
    public init(_ observer: AnyObserver<DBEvent>) {
        self.observer = observer
    }
    
    public func deinitialize() {}
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
        Preconditions.checkNotRunningOnMainThread(nil)
        observer.onNext(dbLevel(controller, DBEvent.didLoad))
        observer.onNext(DBEvent.didChange)
    }
    
    /// Notifies the delegate that section and object changes are about to be
    /// processed and notifications will be sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view.
    public func controllerWillChangeContent(_ controller: Controller) {
        Preconditions.checkNotRunningOnMainThread(nil)
        observer.onNext(DBEvent.willLoad)
        observer.onNext(DBEvent.willChange)
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
        Preconditions.checkNotRunningOnMainThread(nil)
        observer.onNext(DBEvent.objectLevel(type, anObject, indexPath, newIndexPath))
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
        Preconditions.checkNotRunningOnMainThread(nil)
        observer.onNext(DBEvent.sectionLevel(type, sectionInfo, sectionIndex))
    }
}

public extension HMCDResultControllerDelegate {
    
    /// Get a DB change Event from the associated result controller.
    ///
    /// - Parameter controller: A Controller instance.
    /// - Returns: An Event instance.
    public func dbLevel(_ controller: Controller,
                        _ mapper: (DBLevel<Any>) -> DBEvent) -> DBEvent {
        return DBEvent.dbLevel(controller.sections,
                               controller.fetchedObjects,
                               controller.fetchRequest.fetchLimit,
                               mapper)
    }
}
