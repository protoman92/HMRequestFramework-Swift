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

public protocol Dummy1ConvertibleType {
    func asDummy1() -> Dummy1
}

public final class Dummy1: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var int64: Int64
    @NSManaged public var date: Date
    @NSManaged public var float: Float
    
    public convenience init(_ context: NSManagedObjectContext) throws {
        let description = try Dummy1.entityDescription(in: context)
        self.init(entity: description, insertInto: nil)
        Dummy1.counter += 1
        let counter = Dummy1.counter
        id = "id-\(counter)"
        int64 = Int64(counter)
        date = Date()
        float = Float(counter)
    }
}

public extension Dummy1 {
    fileprivate static var counter = 0
}

extension Dummy1: HMCDConvertibleType {
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
extension Dummy1: HMCDType {}

extension Dummy1: HMCDParsableType {
    public typealias CDClass = Dummy1
}

extension Dummy1: HMProtocolConvertibleType {
    public typealias PTCType = Dummy1Type
}

extension Dummy1: Dummy1Type {}

extension Dummy1: Dummy1ConvertibleType {
    public func asDummy1() -> Dummy1 {
        return self
    }
}
