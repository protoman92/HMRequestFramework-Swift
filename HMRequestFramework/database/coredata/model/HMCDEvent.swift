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
    sections: [HMCDSection<V>],
    objects: [V]
)

public typealias ObjectChange<V> = (
    object: V,
    oldIndex: IndexPath?,
    newIndex: IndexPath?
)

public typealias SectionChange<V> = (
    section: HMCDSection<V>,
    sectionIndex: Int
)

/// Use this enum to represent stream events from CoreData.
///
/// - initialize: Used when the stream is first initialized.
/// - willChange: Used when the underlying DB is about to change data.
/// - didChange: Used when the underlying DB has changed data.
/// - anyChange: Used when there is any change in the DB.
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
    case initialize(DBChange<V>)
    case willChange(DBChange<V>)
    case didChange(DBChange<V>)
    case anyChange(DBChange<V>)
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
        let sections = sections?.map(HMCDSection<Any>.init) ?? []
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
        let section = HMCDSection<Any>(section)
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
            return mapObject(f, HMCDEvent<V2>.insert, change)
            
        case .delete(let change):
            return mapObject(f, HMCDEvent<V2>.delete, change)
            
        case .move(let change):
            return mapObject(f, HMCDEvent<V2>.move, change)
            
        case .update(let change):
            return mapObject(f, HMCDEvent<V2>.update, change)
            
        case .insertSection(let change):
            return mapSection(f, HMCDEvent<V2>.insertSection, change)
            
        case .deleteSection(let change):
            return mapSection(f, HMCDEvent<V2>.deleteSection, change)
            
        case .moveSection(let change):
            return mapSection(f, HMCDEvent<V2>.moveSection, change)
            
        case .updateSection(let change):
            return mapSection(f, HMCDEvent<V2>.updateSection, change)
            
        case .initialize(let change):
            return mapDBChange(f, HMCDEvent<V2>.initialize, change)
            
        case .willChange(let change):
            return mapDBChange(f, HMCDEvent<V2>.willChange, change)
            
        case .didChange(let change):
            return mapDBChange(f, HMCDEvent<V2>.didChange, change)
            
        case .anyChange(let change):
            return mapDBChange(f, HMCDEvent<V2>.anyChange, change)
            
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
    
    
    /// Check if the current event is a valid streamable one.
    public func isValidEvent() -> Bool {
        switch self {
        case .dummy:
            return false
            
        default:
            return true
        }
    }
}

extension HMCDEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .insert:           return "insert"
        case .delete:           return "delete"
        case .move:             return "move"
        case .update:           return "update"
        case .insertSection:    return "insertSection"
        case .deleteSection:    return "deleteSection"
        case .moveSection:      return "moveSection"
        case .updateSection:    return "updateSection"
        case .initialize:       return "initialize"
        case .willChange:       return "willChange"
        case .didChange:        return "didChange"
        case .anyChange:        return "anyChange"
        case .dummy:            return "dummy"
        }
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
