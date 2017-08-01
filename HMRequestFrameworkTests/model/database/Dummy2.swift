//
//  Dummy2.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/26/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
@testable import HMRequestFramework

public protocol Dummy2Type {}

public final class Dummy2: NSManagedObject {
    @NSManaged public var string1: String
    @NSManaged public var string2: String
    @NSManaged public var string3: String
    @NSManaged public var string4: String
    @NSManaged public var string5: String
    @NSManaged public var string6: String
    @NSManaged public var string7: String
    @NSManaged public var string8: String
    @NSManaged public var string9: String
    @NSManaged public var string10: String
    
    public convenience init(_ context: NSManagedObjectContext) throws {
        let entity = try Dummy2.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
        let length = 1000
        string1 = String.random(withLength: length)
        string2 = String.random(withLength: length)
        string3 = String.random(withLength: length)
        string4 = String.random(withLength: length)
        string5 = String.random(withLength: length)
        string6 = String.random(withLength: length)
        string7 = String.random(withLength: length)
        string8 = String.random(withLength: length)
        string9 = String.random(withLength: length)
        string10 = String.random(withLength: length)
    }
}

extension Dummy2: DummyType {}

extension Dummy2: HMCDRepresentableType {
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return (1...10).map({index in
            {(_) -> NSAttributeDescription in
                let attribute = NSAttributeDescription()
                attribute.name = "string\(index)"
                attribute.attributeType = .stringAttributeType
                attribute.isOptional = false
                return attribute
            }()
        })
    }
}

extension Dummy2: HMCDPureObjectType {
    public typealias CDClass = Dummy2
}

extension Dummy2: HMProtocolConvertibleType {
    public typealias PTCType = Dummy2Type
    
    public func asProtocol() -> PTCType {
        return self as PTCType
    }
}

extension Dummy2: Dummy2Type {}
