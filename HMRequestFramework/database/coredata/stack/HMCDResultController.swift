//
//  HMCDResultController.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 23/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

/// Controller that wraps a NSFetchedResultController and deliver events with
/// Observable.
public final class HMCDResultController: NSObject {
    public typealias Event = HMCDEvent<Any>
    public typealias Result = NSFetchRequestResult
    public typealias Controller = NSFetchedResultsController<Result>
    fileprivate let dbLevelSubject: BehaviorSubject<Event>
    fileprivate let objectLevelSubject: BehaviorSubject<Event>
    fileprivate let sectionLevelSubject: BehaviorSubject<Event>
    var frc: Controller?
    
    deinit {
        // Make sure references are properly disposed of.
        debugPrint("Deinit \(self)")
    }
    
    override fileprivate init() {
        dbLevelSubject = BehaviorSubject<Event>(value: .dummy)
        objectLevelSubject = BehaviorSubject<Event>(value: .dummy)
        sectionLevelSubject = BehaviorSubject<Event>(value: .dummy)
        super.init()
    }
    
    /// Call this method when the controller instance is built to do some final
    /// set-ups.
    fileprivate func onInstanceBuilt() {
        frc?.delegate = self
    }
    
    /// Delete a cache to prepare for streaming.
    func deleteCache() {
        if let cacheName = controller().cacheName {
            Controller.deleteCache(withName: cacheName)
        }
    }
    
    func eventObservable() -> Observable<Event> {
        return Observable
            .merge(
                dbLevelSubject,
                objectLevelSubject,
                sectionLevelSubject
            )
            .filter({$0.isValidEvent()})
    }
    
    func dbLevelObserver() -> AnyObserver<Event> {
        return dbLevelSubject.asObserver()
    }
    
    func objectLevelObserver() -> AnyObserver<Event> {
        return objectLevelSubject.asObserver()
    }
    
    func sectionLevelObserver() -> AnyObserver<Event> {
        return sectionLevelSubject.asObserver()
    }
    
    /// Get the current objects as identified by the fetch request in DB.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: An Array of PO.
    public func currentObjects<PO>(_ cls: PO.Type) -> [PO] where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return (frc?.fetchedObjects ?? [])
            .flatMap({$0 as? PO.CDClass})
            .map({$0.asPureObject()})
    }
    
    func controller() -> Controller {
        if let frc = self.frc {
            return frc
        } else {
            fatalError("FRC cannot be nil")
        }
    }
}

extension HMCDResultController: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate let controller: Buildable
        
        fileprivate init() {
            controller = Buildable()
        }
        
        /// Set the frc instance.
        ///
        /// - Parameter frc: A NSFetchedResultsController instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(frc: Controller?) -> Self {
            controller.frc = frc
            return self
        }
    }
}

extension HMCDResultController.Builder: HMBuilderType {
    public typealias Buildable = HMCDResultController
    
    /// Override this method to provide default implementation.
    ///
    /// - Parameter buildable: A Buildable instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(buildable: Buildable) -> Self {
        return self.with(frc: buildable.frc)
    }
    
    public func build() -> Buildable {
        controller.onInstanceBuilt()
        return controller
    }
}

extension HMCDResultController: NSFetchedResultsControllerDelegate {
    
    /// Notifies the delegate that all section and object changes have been sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view. Providing an empty implementation will
    /// enable change tracking if you do not care about the individual callbacks.
    public func controllerDidChangeContent(_ controller: Controller) {
//        // Need to do this if we specify fetchLimit/fetchOffset.
//        if shouldRefetchOnChange(controller) {
//            try? controller.performFetch()
//        }
        
        let observer = dbLevelObserver()
        observer.onNext(dbLevel(controller, Event.didLoad))
        observer.onNext(Event.didChange)
    }
    
    /// Notifies the delegate that section and object changes are about to be
    /// processed and notifications will be sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view.
    public func controllerWillChangeContent(_ controller: Controller) {
        let observer = dbLevelObserver()
        observer.onNext(Event.willLoad)
        observer.onNext(Event.willChange)
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
        let observer = objectLevelObserver()
        let event = Event.objectLevel(type, anObject, indexPath, newIndexPath)
        observer.onNext(event)
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
        let observer = sectionLevelObserver()
        let event = Event.sectionLevel(type, sectionInfo, sectionIndex)
        observer.onNext(event)
    }
    
    /// Get a DB change Event from the associated result controller.
    ///
    /// - Parameter controller: A Controller instance.
    /// - Returns: An Event instance.
    func dbLevel(_ controller: Controller,
                 _ mapper: (DBLevel<Any>) -> Event) -> Event {
        return Event.dbLevel(controller.sections,
                             controller.fetchedObjects,
                             mapper)
    }
    
    /// Since controller.fetchObjects reflect the state of the context to
    /// which the FRC is attached, not the persistent store's, so if we specify
    /// fetchLimit/fetchOffset, we must refetch objects from the DB to honor
    /// those limits.
    ///
    /// - Parameter controller: A Controller instance.
    /// - Returns: A Bool value.
    func shouldRefetchOnChange(_ controller: Controller) -> Bool {
        let fetchRequest = controller.fetchRequest
        return fetchRequest.fetchLimit > 0 || fetchRequest.fetchOffset > 0
    }
}
