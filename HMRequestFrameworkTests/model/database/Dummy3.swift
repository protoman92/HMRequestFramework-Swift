//
//  Dummy3.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 28/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
@testable import HMRequestFramework

public protocol Dummy3Type {
    var id: String { get }
}

public class CDDummy3: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var count: Int64
    
    public convenience required init(_ context: NSManagedObjectContext) throws {
        let entity = try CDDummy3.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
}

extension CDDummy3: HMCDObjectBuildableType {
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(CDDummy3(context))
    }
    
    public final class Builder: HMCDObjectBuilderType {
        public typealias PureObject = Dummy3
        
        private let cdo: CDDummy3
        
        fileprivate init(_ cdo: PureObject.CDClass) {
            self.cdo = cdo
        }
        
        public func with(pureObject: PureObject) -> Self {
            cdo.id = pureObject.id
            cdo.count = pureObject.count
            return self
        }
        
        public func build() -> PureObject.CDClass {
            return cdo
        }
    }
}

extension CDDummy3: HMCDObjectType {
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
}

extension CDDummy3: HMCDPureObjectConvertibleType {
    public typealias PureObject = Dummy3
}

public class Dummy3 {
    fileprivate static var counter = 0
    
    public var id: String
    public var count: Int64
    
    init() {
        Dummy3.counter += 1
        id = "\(Dummy3.counter)"
        count = Int64(Int.random(0, 100))
    }
}

extension Dummy3: CustomStringConvertible {
    public var description: String {
        return "id: \(id), count: \(count)"
    }
}

extension Dummy3: Equatable {
    public static func ==(lhs: Dummy3, rhs: Dummy3) -> Bool {
        return lhs.id == rhs.id && lhs.count == rhs.count
    }
}

extension Dummy3: HMCDPureObjectType {
    public typealias CDClass = CDDummy3
}

extension Dummy3: HMCDPureObjectBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: HMCDPureObjectBuilderType {
        public typealias Buildable = Dummy3
        
        private let dummy = Buildable()
        
        public func with(cdObject: Buildable.CDClass) -> Self {
            dummy.id = cdObject.id
            dummy.count = cdObject.count
            return self
        }
        
        public func with(buildable: Buildable) -> Self {
            dummy.id = buildable.id
            dummy.count = buildable.count
            return self
        }
        
        public func build() -> Buildable {
            return dummy
        }
    }
}
