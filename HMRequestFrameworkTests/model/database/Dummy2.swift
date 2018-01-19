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
    var id2: String { get }
    var count: Int64 { get }
}

public extension Dummy2Type {
    public func primaryKey() -> String {
        return "id2"
    }
    
    public func primaryValue() -> String? {
        return id2
    }
    
    public func stringRepresentationForResult() -> String {
        return id2
    }
}

public final class CDDummy2: NSManagedObject {
    @NSManaged public var id2: String
    @NSManaged public var count: Int64
    
    convenience public init(_ context: Context) throws {
        let entity = try CDDummy2.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
}

public final class Dummy2 {
    fileprivate static var counter = 0
    
    fileprivate var _id2: String
    fileprivate var _count: Int64
    
    public var id2: String {
        return _id2
    }
    
    public var count: Int64 {
        return _count
    }
    
    init() {
        Dummy2.counter += 1
        _id2 = "\(Dummy2.counter)"
        _count = Int64(Int.random(0, 10000))
    }
}

extension CDDummy2: Dummy2Type {}

extension CDDummy2: HMCDObjectMasterType {
    public typealias PureObject = Dummy2
    
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id2")
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
    
    public func mutateWithPureObject(_ object: PureObject) {
        id2 = object.id2
        count = object.count
    }
}

extension Dummy2: Dummy2Type {}

extension Dummy2: CustomStringConvertible {
    public var description: String {
        return "id2: \(id2)-count: \(count)"
    }
}

extension Dummy2: Equatable {
    public static func ==(lhs: Dummy2, rhs: Dummy2) -> Bool {
        return lhs.id2 == rhs.id2 && lhs.count == rhs.count
    }
}

extension Dummy2: HMCDPureObjectMasterType {
    public typealias CDClass = CDDummy2

    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate let d2: Buildable
        
        fileprivate init() {
            d2 = Buildable()
        }
        
        public func with(dummy2: Dummy2Type?) -> Self {
            if let dummy2 = dummy2 {
                d2._id2 = dummy2.id2
                d2._count = dummy2.count
                return self
            } else {
                return self
            }
        }
    }
}

extension Dummy2.Builder: HMCDPureObjectBuilderMasterType {
    public typealias Buildable = Dummy2
    
    public func with(cdObject: Buildable.CDClass) -> Self {
        return with(dummy2: cdObject)
    }
    
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return with(dummy2: buildable)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return d2
    }
}
