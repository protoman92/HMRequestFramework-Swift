//
//  HMCDEvent.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import SwiftUtilities

public typealias SectionInfo = NSFetchedResultsSectionInfo
public typealias ObjectChange = (oldIndex: IndexPath?, newIndex: IndexPath?)
public typealias SectionChange = (sectionInfo: SectionInfo, sectionIndex: Int)

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
    case willChange([V])
    case didChange([V])
    case insert(V, ObjectChange)
    case delete(V, ObjectChange)
    case move(V, ObjectChange)
    case update(V, ObjectChange)
    case insertSection(SectionChange)
    case deleteSection(SectionChange)
    case moveSection(SectionChange)
    case updateSection(SectionChange)
    case dummy
    
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
        let change = ObjectChange(oldIndex: oldIndex, newIndex: newIndex)
        
        switch type {
        case .insert:
            return .insert(object, change)
            
        case .delete:
            return .delete(object, change)
            
        case .move:
            return .move(object, change)
            
        case .update:
            return .update(object, change)
        }
    }
    
    /// Map a section change to an instance of this enum.
    ///
    /// - Parameters:
    ///   - type: A NSFetchResultsChangeType instance.
    ///   - sectionInfo: A NSFetchedResultsSectionInfo instance.
    ///   - sectionIndex: An Int value.
    /// - Returns: A HMCDEvent instance.
    public static func sectionChange(_ type: NSFetchedResultsChangeType,
                                     _ sectionInfo: NSFetchedResultsSectionInfo,
                                     _ sectionIndex: Int) -> HMCDEvent<V> {
        let change = SectionChange(sectionInfo: sectionInfo,
                                   sectionIndex: sectionIndex)
        
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
        case .insert(let value, let change):
            return mapObjectChange(f, {.insert($0.0, $0.1)}, value, change)
            
        case .delete(let value, let change):
            return mapObjectChange(f, {.delete($0.0, $0.1)}, value, change)
            
        case .move(let value, let change):
            return mapObjectChange(f, {.move($0.0, $0.1)}, value, change)
            
        case .update(let value, let change):
            return mapObjectChange(f, {.update($0.0, $0.1)}, value, change)
            
        case .insertSection(let change):
            return .insertSection(change)
            
        case .deleteSection(let change):
            return .deleteSection(change)
            
        case .moveSection(let change):
            return .moveSection(change)
            
        case .updateSection(let change):
            return .updateSection(change)
            
        case .willChange(let objects):
            return .willChange(objects.flatMap({try? f($0)}))
            
        case .didChange(let objects):
            return .didChange(objects.flatMap({try? f($0)}))
            
        case .dummy:
            return .dummy
        }
    }
    
    /// Convenience method to map the enum instance's generic.
    ///
    /// - Parameter type: The V2 class type.
    /// - Returns: A HMCDEvent instance.
    public func cast<V2>(to type: V2.Type) -> HMCDEvent<V2> {
        return map({
            if let v2 = $0 as? V2 {
                return v2
            } else {
                throw Exception("Unabled to cast \($0)")
            }
        })
    }
}

public extension HMCDEvent {
    
    /// Map an insert event to another insert event with a different generics.
    ///
    /// - Parameters:
    ///   - f: V transformer.
    ///   - m: Enum mapper so that we can reuse this for multiple object changes.
    ///   - value: A V instance.
    ///   - change: An ObjectChange instance.
    /// - Returns: A HMCDEvent instance.
    fileprivate func mapObjectChange<V2>(_ f: (V) throws -> V2,
                                         _ m: ((V2, ObjectChange) -> HMCDEvent<V2>),
                                         _ value: V,
                                         _ change: ObjectChange) -> HMCDEvent<V2> {
        if let value = try? f(value) {
            return m(value, change)
        } else {
            return .dummy
        }
    }
}
