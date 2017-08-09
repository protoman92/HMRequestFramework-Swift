//
//  Dummy2.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 28/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
@testable import HMRequestFramework

public protocol Dummy2Type {
    var id: String { get set }
    var count: Int64 { get set }
}

public final class CDDummy2: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var count: Int64
    
    public convenience required init(_ context: NSManagedObjectContext) throws {
        let entity = try CDDummy2.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
}

public final class Dummy2 {
    fileprivate static var counter = 0
    
    public var id: String
    public var count: Int64
    
    init() {
        Dummy2.counter += 1
        id = "\(Dummy2.counter)"
        count = Int64(Int.random(0, 100))
    }
}

public class Dummy2Builder<D2: Dummy2Type> {
    fileprivate var d2: D2
    
    fileprivate init(_ d2: D2) {
        self.d2 = d2
    }
    
    public func with(dummy2: Dummy2Type) -> Self {
        d2.id = dummy2.id
        d2.count = dummy2.count
        return self
    }
    
    public func build() -> D2 {
        return d2
    }
}

extension CDDummy2: Dummy2Type {}

extension CDDummy2: HMCDObjectMasterType {
    public typealias PureObject = Dummy2
    
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id")
                .shouldNotBeOptional()
                .with(type: .stringAttributeType)
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "count")
                .shouldBeOptional()
                .with(type: .integer64AttributeType)
                .build()
        ]
    }
    
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(CDDummy2(context))
    }
    
    public final class Builder: Dummy2Builder<CDDummy2> {
        fileprivate override init(_ cdo: PureObject.CDClass) {
            super.init(cdo)
        }
    }
}

extension CDDummy2.Builder: HMCDObjectBuilderMasterType {
    public typealias PureObject = Dummy2
    
    public func with(pureObject: PureObject) -> Self {
        return with(dummy2: pureObject)
    }
}

extension Dummy2: Dummy2Type {}

extension Dummy2: Equatable {
    public static func ==(lhs: Dummy2, rhs: Dummy2) -> Bool {
        return lhs.id == rhs.id && lhs.count == rhs.count
    }
}

extension Dummy2: HMCDPureObjectMasterType {
    public typealias CDClass = CDDummy2

    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: Dummy2Builder<Dummy2> {
        fileprivate init() {
            super.init(Dummy2())
        }
    }
}

extension Dummy2.Builder: HMCDPureObjectBuilderMasterType {
    public typealias Buildable = Dummy2
    
    public func with(cdObject: Buildable.CDClass) -> Self {
        return with(dummy2: cdObject)
    }
    
    public func with(buildable: Buildable) -> Self {
        return with(dummy2: buildable)
    }
}
