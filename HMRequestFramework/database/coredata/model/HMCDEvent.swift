//
//  HMCDEvent.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

/// Use this enum to represent stream events from CoreData. There are two ways
/// we can use these events to represent DB data:
///
/// - Only subscribe to didLoad, and whenever data arrives, reload the view or
///   diff the data set to detect changes and animate them. This is suitable
///   for smaller data set.
///
/// - Subscribe to all events and treat them as if we were using FRC delegate.
///   E.g. when willChange arrives we begin updating the view, and stop doing
///   so upon didChange. The other events carry information about the specific
///   objects/sections that have changed.
///
/// - willLoad: Used when the underlying DB is about to change data.
/// - didLoad: Used when the underlying DB has changed data.
/// - willChange: Used when the data set is about to change.
/// - didChange: Used when the data set has just changed.
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
    case willLoad
    case didLoad(DBLevel)
    case willChange
    case didChange
    case insert(ObjectLevel)
    case delete(ObjectLevel)
    case move(ObjectLevel)
    case update(ObjectLevel)
    case insertSection(SectionLevel)
    case deleteSection(SectionLevel)
    case moveSection(SectionLevel)
    case updateSection(SectionLevel)
    case dummy
    
    public typealias DBLevel = [HMCDSection<V>]
    
    public typealias ObjectLevel = (
        object: V,
        oldIndex: IndexPath?,
        newIndex: IndexPath?
    )
    
    public typealias SectionLevel = (
        section: HMCDSection<V>,
        index: Int
    )
    
    /// Map a DB change type to an instance of this enum.
    ///
    /// - Parameters:
    ///   - sections: An Array of NSFetchedResultsSectionInfo.
    ///   - objects: An Array of Any.
    ///   - fetchLimit: An Int value denoting the maximum number of objects in
    ///                 a section.
    ///   - m: Mapper function to create the enum instance.
    /// - Returns: A HMCDEvent instance.
    public static func dbLevel(_ sections: [NSFetchedResultsSectionInfo]?,
                               _ objects: [Any]?,
                               _ fetchLimit: Int,
                               _ m: (HMCDEvent<Any>.DBLevel) -> HMCDEvent<Any>)
        -> HMCDEvent<Any>
    {
        let limit = fetchLimit > 0 ? fetchLimit : Int.max 
        let sections = sections?.map(HMCDSection<Any>.init) ?? []
        let slicedSections = HMCDSections.sectionsWithLimit(sections, limit)
        return m(HMCDEvent<Any>.DBLevel(slicedSections))
    }
    
    /// Map an object change type to an instance of this enum.
    ///
    /// - Parameters:
    ///   - type: A NSFetchedResultsChangeType instance.
    ///   - object: A V instance.
    ///   - oldIndex: An IndexPath instance.
    ///   - newIndex: An IndexPath instance.
    /// - Returns: A HMCDEvent instance.
    public static func objectLevel(_ type: NSFetchedResultsChangeType,
                                   _ object: V,
                                   _ oldIndex: IndexPath?,
                                   _ newIndex: IndexPath?) -> HMCDEvent<V> {
        let change = HMCDEvent<V>.ObjectLevel(object: object,
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
    public static func sectionLevel(_ type: NSFetchedResultsChangeType,
                                    _ section: NSFetchedResultsSectionInfo,
                                    _ index: Int) -> HMCDEvent<Any> {
        let section = HMCDSection<Any>.init(section)
        let change = HMCDEvent<Any>.SectionLevel(section: section, index: index)
        
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
            
        case .willLoad:
            return .willLoad
            
        case .didLoad(let change):
            return mapDB(f, {.didLoad($0)}, change)
            
        case .willChange:
            return .willChange
            
        case .didChange:
            return .didChange
            
        default:
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
        case .willLoad:         return "willLoad"
        case .didLoad:          return "didLoad"
        case .willChange:       return "willChange"
        case .didChange:        return "didChange"
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
    ///   - change: An DBLevel instance.
    /// - Returns: A HMCDEvent instance.
    func mapDB<V2>(_ f: (V) throws -> V2,
                   _ m: ((HMCDEvent<V2>.DBLevel)) -> HMCDEvent<V2>,
                   _ change: HMCDEvent<V>.DBLevel) -> HMCDEvent<V2> {
        let sections = change.map({$0.map(f)})
        return m(HMCDEvent<V2>.DBLevel(sections))
    }
    
    /// Map an object event to another object event with a different generics.
    ///
    /// - Parameters:
    ///   - f: V transformer.
    ///   - m: Enum mapper so that we can reuse this for multiple object changes.
    ///   - change: An ObjectLevel instance.
    /// - Returns: A HMCDEvent instance.
    func mapObject<V2>(_ f: (V) throws -> V2,
                       _ m: ((HMCDEvent<V2>.ObjectLevel) -> HMCDEvent<V2>),
                       _ change: HMCDEvent<V>.ObjectLevel) -> HMCDEvent<V2> {
        if let value = try? f(change.object) {
            return m(HMCDEvent<V2>.ObjectLevel(object: value,
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
    ///   - change: An SectionLevel instance.
    /// - Returns: A HMCDEvent instance.
    func mapSection<V2>(_ f: (V) throws -> V2,
                        _ m: ((HMCDEvent<V2>.SectionLevel) -> HMCDEvent<V2>),
                        _ change: HMCDEvent<V>.SectionLevel) -> HMCDEvent<V2> {
        return m(HMCDEvent<V2>.SectionLevel(section: change.section.map(f),
                                            index: change.index))
    }
}
