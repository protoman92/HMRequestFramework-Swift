//
//  Dummy1.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxDataSources
import SwiftUtilities
@testable import HMRequestFramework

public protocol Dummy1Type {
    var id: String? { get set }
    var date: Date? { get set }
    var int64: NSNumber? { get set }
    var float: NSNumber? { get set }
    var version: NSNumber? { get set }
}

public extension Dummy1Type {
    public func primaryKey() -> String {
        return "id"
    }
    
    public func primaryValue() -> String? {
        return id
    }
}

public final class CDDummy1: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var int64: NSNumber?
    @NSManaged public var date: Date?
    @NSManaged public var float: NSNumber?
    @NSManaged public var version: NSNumber?
    
    public convenience init(_ context: NSManagedObjectContext) throws {
        let entity = try CDDummy1.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
}

public final class Dummy1 {
    fileprivate static var counter = 0
    
    public var id: String?
    public var int64: NSNumber?
    public var date: Date?
    public var float: NSNumber?
    public var version: NSNumber?
    
    public init() {
        Dummy1.counter += 1
        let counter = Dummy1.counter
        id = "id-\(counter)"
        date = Date.random()
        int64 = Int64(Int.randomBetween(0, 10000)) as NSNumber
        float = Float(Int.randomBetween(0, 10000)) as NSNumber
        version = 1
    }
}

public class Dummy1Builder<D1: Dummy1Type> {
    fileprivate var d1: D1
    
    fileprivate init(_ d1: D1) {
        self.d1 = d1
    }
    
    @discardableResult
    public func with(id: String?) -> Self {
        d1.id = id
        return self
    }
    
    @discardableResult
    public func with(date: Date?) -> Self {
        d1.date = date
        return self
    }
    
    @discardableResult
    public func with(int64: NSNumber?) -> Self {
        d1.int64 = int64
        return self
    }
    
    @discardableResult
    public func with(float: NSNumber?) -> Self {
        d1.float = float
        return self
    }
    
    @discardableResult
    public func with(version: NSNumber?) -> Self {
        d1.version = version
        return self
    }
    
    @discardableResult
    public func with(version: String?) -> Self {
        if let version = version, let dbl = Double(version) {
            return with(version: NSNumber(value: dbl).intValue as NSNumber)
        } else {
            return self
        }
    }
    
    public func with(dummy1: Dummy1Type) -> Self {
        return self
            .with(id: dummy1.id)
            .with(date: dummy1.date)
            .with(int64: dummy1.int64)
            .with(float: dummy1.float)
            .with(version: dummy1.version)
    }
    
    public func build() -> D1 {
        return d1
    }
}

extension CDDummy1: Dummy1Type {}

extension CDDummy1: HMCDVersionableMasterType {
    public typealias PureObject = Dummy1
    
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id")
                .with(type: .stringAttributeType)
                .shouldNotBeOptional()
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "int64")
                .with(type: .integer64AttributeType)
                .shouldNotBeOptional()
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "date")
                .with(type: .dateAttributeType)
                .shouldNotBeOptional()
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "float")
                .with(type: .floatAttributeType)
                .shouldNotBeOptional()
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "version")
                .with(type: .integer16AttributeType)
                .shouldNotBeOptional()
                .build()
        ]
    }
    
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(Dummy1.CDClass.init(context))
    }
    
    public final class Builder: Dummy1Builder<CDDummy1> {
        override fileprivate init(_ cdo: PureObject.CDClass) {
            super.init(cdo)
        }
    }
    
    public func currentVersion() -> String? {
        if let version = self.version {
            return String(describing: version)
        } else {
            return nil
        }
    }
    
    public func oneVersionHigher() -> String? {
        if let version = self.version {
            return String(describing: version.intValue + 1)
        } else {
            return nil
        }
    }
    
    public func hasPreferableVersion(over obj: HMVersionableType) throws -> Bool {
        if let v1 = self.currentVersion(), let v2 = obj.currentVersion() {
            return v1 >= v2
        } else {
            throw Exception("Version not available")
        }
    }
    
    public func updateVersion(_ version: String?) {
        if let version = version, let dbl = Double(version) {
            self.version = NSNumber(value: dbl).intValue as NSNumber
        }
    }
    
    public func updateKeys() -> [String] {
        return ["id", "date", "int64", "float", "version"]
    }
}

extension CDDummy1.Builder: HMCDObjectBuilderMasterType {
    public typealias PureObject = Dummy1
    
    public func with(pureObject: PureObject) -> Self {
        return with(dummy1: pureObject)
    }
    
    public func with(buildable: Buildable) -> Self {
        return with(dummy1: buildable)
    }
}

extension Dummy1: Equatable {
    public static func ==(lhs: Dummy1, rhs: Dummy1) -> Bool {
        // We don't compare the version here because it will be bumped when
        // an update is successful. During testing, we only compare the other
        // properties to make sure that the updated object is the same as this.
        return lhs.id == rhs.id &&
            lhs.date == rhs.date &&
            lhs.int64 == rhs.int64 &&
            lhs.float == rhs.float
    }
}

extension Dummy1: IdentifiableType {
    public var identity: String {
        return id ?? ""
    }
}

extension Dummy1: Dummy1Type {}

extension Dummy1: CustomStringConvertible {
    public var description: String {
        return "PureObject - id: \(String(describing: id)), " +
            "int64: \(String(describing: int64)), " +
            "float: \(String(describing: float)), " +
            "date: \(String(describing: date)), " +
            "version: \(String(describing: version))"
    }
}

extension Dummy1: HMCDUpsertablePureObjectMasterType {
    public typealias CDClass = CDDummy1

    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: Dummy1Builder<Dummy1> {
        fileprivate init() {
            super.init(Dummy1())
        }
    }
}

extension Dummy1.Builder: HMCDPureObjectBuilderMasterType {
    public typealias Buildable = Dummy1
    
    public func with(cdObject: Buildable.CDClass) -> Self {
        return with(dummy1: cdObject)
    }
    
    public func with(buildable: Buildable) -> Self {
        return with(dummy1: buildable)
    }
}
