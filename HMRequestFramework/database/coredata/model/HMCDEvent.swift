//
//  HMCDEvent.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

public typealias DBChange<V> = (
    sections: [HMCDSectionInfo<V>],
    objects: [V]
)

public typealias ObjectChange<V> = (
    object: V,
    oldIndex: IndexPath?,
    newIndex: IndexPath?
)

public typealias SectionChange<V> = (
    section: HMCDSectionInfo<V>,
    sectionIndex: Int
)

/// Use this enum to represent stream events from CoreData.
///
/// - willChange: Used when the underlying DB is about to change data.
/// - didChange: Used when the underlying DB has changed data.
/// - insert: Used when some objects were inserted.
/// - delete: Used when some objects were deleted.
/// - move: Used when some objects were moved.
/// - update: Used when some objects were updated.
/// - insertSection: Used when a section is inserted.
/// - deleteSection: Used when a section is deleted.
/// - moveSection: Used when a section is moved.
/// - updateSection: Used when a section is updated.
/// - dummy: Used when we cannot categorize this even anywhere else.
public enum HMCDEvent<V> {
    case willChange(DBChange<V>)
    case didChange(DBChange<V>)
    case insert(ObjectChange<V>)
    case delete(ObjectChange<V>)
    case move(ObjectChange<V>)
    case update(ObjectChange<V>)
    case insertSection(SectionChange<V>)
    case deleteSection(SectionChange<V>)
    case moveSection(SectionChange<V>)
    case updateSection(SectionChange<V>)
    case dummy
    
    /// Map a DB change type to an instance of this enum.
    ///
    /// - Parameters:
    ///   - sections: An Array of NSFetchedResultsSectionInfo.
    ///   - objects: An Array of Any.
    ///   - m: Mapper function to create the enum instance.
    /// - Returns: A HMCDEvent instance.
    public static func dbChange(_ sections: [NSFetchedResultsSectionInfo]?,
                                _ objects: [Any]?,
                                _ m: (DBChange<Any>) -> HMCDEvent<Any>)
        -> HMCDEvent<Any>
    {
        let objects = objects ?? []
        let sections = sections?.map(HMCDSectionInfo<Any>.init) ?? []
        return m(DBChange(sections: sections, objects: objects))
    }
    
    /// Map an object change type to an instance of this enum.
    ///
    /// - Parameters:
    ///   - type: A NSFetchedResultsChangeType instance.
    ///   - object: A V instance.
    ///   - oldIndex: An IndexPath instance.
    ///   - newIndex: An IndexPath instance.
    /// - Returns: A HMCDEvent instance.
    public static func objectChange(_ type: NSFetchedResultsChangeType,
                                    _ object: V,
                                    _ oldIndex: IndexPath?,
                                    _ newIndex: IndexPath?) -> HMCDEvent<V> {
        let change = ObjectChange<V>(object: object,
                                     oldIndex: oldIndex,
                                     newIndex: newIndex)
        
        switch type {
        case .insert:
            return .insert(change)
            
        case .delete:
            return .delete(change)
            
        case .move:
            return .move(change)
            
        case .update:
            return .update(change)
        }
    }
    
    /// Map a section change to an instance of this enum. This method is only
    /// applicable for an Event with Any generic.
    ///
    /// To get pure objects, the handler will have to explicitly map the Any
    /// objects Array to an Array of pure object convertibles, and then convert
    /// those objects to their PO forms.
    ///
    /// - Parameters:
    ///   - type: A NSFetchResultsChangeType instance.
    ///   - section: A NSFetchedResultsSectionInfo instance.
    ///   - sectionIndex: An Int value.
    /// - Returns: A HMCDEvent instance.
    public static func sectionChange(_ type: NSFetchedResultsChangeType,
                                     _ section: NSFetchedResultsSectionInfo,
                                     _ sectionIndex: Int) -> HMCDEvent<Any> {
        let section = HMCDSectionInfo<Any>(section)
        let change = SectionChange(section: section, sectionIndex: sectionIndex)
        
        switch type {
        case .insert:
            return .insertSection(change)
            
        case .delete:
            return .deleteSection(change)
            
        case .move:
            return .moveSection(change)
            
        case .update:
            return .updateSection(change)
        }
    }
    
    /// Map the current enum case to the same case with a different generic.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMCDEvent instance.
    public func map<V2>(_ f: (V) throws -> V2) -> HMCDEvent<V2> {
        switch self {
        case .insert(let change):
            return mapObject(f, {.insert($0)}, change)
            
        case .delete(let change):
            return mapObject(f, {.delete($0)}, change)
            
        case .move(let change):
            return mapObject(f, {.move($0)}, change)
            
        case .update(let change):
            return mapObject(f, {.update($0)}, change)
            
        case .insertSection(let change):
            return mapSection(f, {.insertSection($0)}, change)
            
        case .deleteSection(let change):
            return mapSection(f, {.deleteSection($0)}, change)
            
        case .moveSection(let change):
            return mapSection(f, {.moveSection($0)}, change)
            
        case .updateSection(let change):
            return mapSection(f, {.updateSection($0)}, change)
            
        case .willChange(let change):
            return mapDBChange(f, {.willChange($0)}, change)
            
        case .didChange(let change):
            return mapDBChange(f, {.didChange($0)}, change)
            
        case .dummy:
            return .dummy
        }
    }
    
    /// Convenience method to map the enum instance's generic.
    ///
    /// - Parameter cls: The V2 class type.
    /// - Returns: A HMCDEvent instance.
    public func cast<V2>(to cls: V2.Type) -> HMCDEvent<V2> {
        return map({
            if let v2 = $0 as? V2 {
                return v2
            } else {
                throw Exception("Unabled to cast \($0) to \(cls)")
            }
        })
    }
}

public extension HMCDEvent {
    
    /// Map an DB event to another DB event with a different generics.
    ///
    /// - Parameters:
    ///   - f: V transformer.
    ///   - m: Enum mapper so that we can reuse this for multiple DB changes.
    ///   - change: An DBChange instance.
    /// - Returns: A HMCDEvent instance.
    fileprivate func mapDBChange<V2>(_ f: (V) throws -> V2,
                                     _ m: ((DBChange<V2>)) -> HMCDEvent<V2>,
                                     _ change: DBChange<V>) -> HMCDEvent<V2> {
        let sections = change.sections.map({$0.map(f)})
        let objects = change.objects.flatMap({try? f($0)})
        return m(DBChange(sections: sections, objects: objects))
    }
    
    /// Map an object event to another object event with a different generics.
    ///
    /// - Parameters:
    ///   - f: V transformer.
    ///   - m: Enum mapper so that we can reuse this for multiple object changes.
    ///   - change: An ObjectChange instance.
    /// - Returns: A HMCDEvent instance.
    fileprivate func mapObject<V2>(_ f: (V) throws -> V2,
                                   _ m: ((ObjectChange<V2>) -> HMCDEvent<V2>),
                                   _ change: ObjectChange<V>) -> HMCDEvent<V2> {
        if let value = try? f(change.object) {
            return m(ObjectChange(object: value,
                                  oldIndex: change.oldIndex,
                                  newIndex: change.newIndex))
        } else {
            return .dummy
        }
    }
    
    /// Map an section event to another section event with a different generics.
    ///
    /// - Parameters:
    ///   - f: V transformer.
    ///   - m: Enum mapper so that we can reuse this for multiple section changes.
    ///   - change: An SectionChange instance.
    /// - Returns: A HMCDEvent instance.
    fileprivate func mapSection<V2>(_ f: (V) throws -> V2,
                                    _ m: ((SectionChange<V2>) -> HMCDEvent<V2>),
                                    _ change: SectionChange<V>) -> HMCDEvent<V2> {
        return m(SectionChange(section: change.section.map(f),
                               sectionIndex: change.sectionIndex))
    }
}
