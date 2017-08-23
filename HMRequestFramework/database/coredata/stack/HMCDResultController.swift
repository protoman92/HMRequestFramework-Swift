//
//  HMCDResultController.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 23/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift

/// Controller that wraps a NSFetchedResultController and deliver events with
/// Observable.
public final class HMCDResultController: NSObject {
    public typealias Result = NSFetchRequestResult
    public typealias Controller = NSFetchedResultsController<Result>
    fileprivate let cdSubject: BehaviorSubject<[Result]>
    fileprivate var frc: Controller?
    
    override fileprivate init() {
        cdSubject = BehaviorSubject<[Result]>(value: [])
        super.init()
    }
    
    /// Call this method when the controller instance is built to do some final
    /// set-ups.
    fileprivate func onInstanceBuilt() {
        frc?.delegate = self
    }
    
    fileprivate func controller() -> Controller {
        if let frc = self.frc {
            return frc
        } else {
            fatalError("FRC cannot be nil")
        }
    }
    
    /// Start the stream.
    ///
    /// - Throws: Exception if the stream cannot be started.
    public func startStream() throws {
        try controller().performFetch()
    }
    
    /// Get an Observable stream that only emits pure objects of some type.
    ///
    /// - Parameter cls: The PO class type.
    /// - Returns: An Observable instance.
    public func pureObjectStream<PO>(_ cls: PO.Type) -> Observable<[PO]> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDPureObjectConvertibleType,
        PO.CDClass.PureObject == PO
    {
        return cdSubject
            .map({$0.flatMap({$0 as? PO.CDClass})})
            .map({$0.map({$0.asPureObject()})})
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
        if let fetchedObjects = controller.fetchedObjects {
            cdSubject.onNext(fetchedObjects)
        }
    }
    
    /// Notifies the delegate that section and object changes are about to be
    /// processed and notifications will be sent.
    ///
    /// Enables NSFetchedResultsController change tracking.
    ///
    /// Clients may prepare for a batch of updates by using this method to begin
    /// an update block for their view.
    public func controllerWillChangeContent(_ controller: Controller) {}
    
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
    /// predicate. Only the Inserted/Deleted object is reported; like inserting/deleting
    /// from an array, it's assumed that all objects that come after the affected
    /// object shift appropriately.
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
                           newIndexPath: IndexPath?) {}
    
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
                           for type: NSFetchedResultsChangeType) {}
}
