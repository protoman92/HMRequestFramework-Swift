//
//  Dummy1.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
@testable import HMRequestFramework

public protocol Dummy1Type {
    var id: String? { get set }
    var date: Date? { get set }
    var int64: NSNumber? { get set }
    var float: NSNumber? { get set }
}

public final class CDDummy1: HMCDIdentifiableObject {
    @NSManaged public var id: String?
    @NSManaged public var int64: NSNumber?
    @NSManaged public var date: Date?
    @NSManaged public var float: NSNumber?
    
    public override var description: String {
        return "id: \(String(describing: id))"
    }
    
    public convenience init(_ context: NSManagedObjectContext) throws {
        let entity = try CDDummy1.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
    
    public override func primaryKey() -> String {
        return "id"
    }
    
    public override func primaryValue() -> String {
        return id!
    }
}

public final class Dummy1 {
    fileprivate static var counter = 0
    
    public var id: String?
    public var int64: NSNumber?
    public var date: Date?
    public var float: NSNumber?
    
    public init() {
        Dummy1.counter += 1
        let counter = Dummy1.counter
        id = "id-\(counter)"
        date = Date()
        int64 = Int64(counter) as NSNumber
        float = Float(counter) as NSNumber
    }
}

public class Dummy1Builder<D1: Dummy1Type> {
    fileprivate var d1: D1
    
    fileprivate init(_ d1: D1) {
        self.d1 = d1
    }
    
    public func with(dummy1: Dummy1Type) -> Self {
        d1.id = dummy1.id
        d1.date = dummy1.date
        d1.int64 = dummy1.int64
        d1.float = dummy1.float
        return self
    }
    
    public func build() -> D1 {
        return d1
    }
}

extension CDDummy1: HMCDObjectType {
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
                .build()
        ]
    }
}

extension CDDummy1: Dummy1Type {}

extension CDDummy1: HMCDPureObjectConvertibleType {
    public typealias PureObject = Dummy1
}

extension CDDummy1: HMCDObjectBuildableType {
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(Dummy1.CDClass.init(context))
    }
    
    public final class Builder: Dummy1Builder<CDDummy1> {
        fileprivate override init(_ cdo: PureObject.CDClass) {
            super.init(cdo)
        }
    }
}

extension CDDummy1.Builder: HMCDObjectBuilderType {
    public typealias PureObject = Dummy1
    
    public func with(pureObject: PureObject) -> Self {
        return with(dummy1: pureObject)
    }
}

extension Dummy1: Dummy1Type {}

extension Dummy1: HMCDPureObjectType {
    public typealias CDClass = CDDummy1
}

extension Dummy1: HMCDPureObjectBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: Dummy1Builder<Dummy1> {
        fileprivate init() {
            super.init(Dummy1())
        }
    }
}

extension Dummy1.Builder: HMCDPureObjectBuilderType {
    public typealias Buildable = Dummy1
    
    public func with(cdObject: Buildable.CDClass) -> Self {
        return with(dummy1: cdObject)
    }
    
    public func with(buildable: Buildable) -> Self {
        return with(dummy1: buildable)
    }
}
