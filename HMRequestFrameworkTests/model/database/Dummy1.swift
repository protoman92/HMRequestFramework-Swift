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
    var id: String { get }
    var int64: Int64 { get }
    var date: Date { get }
    var float: Float { get }
}

public final class Dummy1: HMCDUpsertableObject {
    fileprivate static var counter = 0
    
    @NSManaged public var id: String
    @NSManaged public var int64: Int64
    @NSManaged public var date: Date
    @NSManaged public var float: Float
    
    public override var description: String {
        return "id: \(id), int64: \(int64)"
    }
    
    public convenience init(_ context: NSManagedObjectContext) throws {
        let entity = try Dummy1.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
        Dummy1.counter += 1
        let counter = Dummy1.counter
        id = "id-\(counter)"
        int64 = Int64(counter)
        date = Date()
        float = Float(counter)
    }
    
    public override func primaryKey() -> String {
        return "id"
    }
    
    public override func primaryValue() -> String {
        return id
    }
}

extension Dummy1: HMCDRepresentableType {
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            {(_) -> NSAttributeDescription in
                let attribute = NSAttributeDescription()
                attribute.name = "id"
                attribute.attributeType = .stringAttributeType
                attribute.isOptional = false
                return attribute
            }(),
            {(_) -> NSAttributeDescription in
                let attribute = NSAttributeDescription()
                attribute.name = "int64"
                attribute.attributeType = .integer64AttributeType
                attribute.isOptional = false
                return attribute
            }(),
            {(_) -> NSAttributeDescription in
                let attribute = NSAttributeDescription()
                attribute.name = "date"
                attribute.attributeType = .dateAttributeType
                attribute.isOptional = false
                return attribute
            }(),
            {(_) -> NSAttributeDescription in
                let attribute = NSAttributeDescription()
                attribute.name = "float"
                attribute.attributeType = NSAttributeType.floatAttributeType
                attribute.isOptional = false
                return attribute
            }()
        ]
    }
}

extension Dummy1: DummyType {}

extension Dummy1: HMCDPureObjectType {
    public typealias CDClass = Dummy1
}

extension Dummy1: HMProtocolConvertibleType {
    public typealias PTCType = Dummy1Type
    
    public func asProtocol() -> PTCType {
        return self as PTCType
    }
}

extension Dummy1: Dummy1Type {}
