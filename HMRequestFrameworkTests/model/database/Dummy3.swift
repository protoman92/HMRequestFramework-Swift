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

public class HMCDDummy3: NSManagedObject {
    @NSManaged var id: String
    
    public convenience required init(_ context: NSManagedObjectContext) throws {
        let entity = try HMCDDummy3.entityDescription()
        self.init(entity: entity, insertInto: nil)
        id = ""
    }
}

extension HMCDDummy3: HMCDBuildable {
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(HMCDDummy3(context))
    }
    
    public final class Builder: HMCDBuilder {
        public typealias Base = Dummy3
        
        private let cdo: HMCDDummy3
        
        fileprivate init(_ cdo: HMCDDummy3) {
            self.cdo = cdo
        }
        
        public func with(base: Dummy3) -> Builder {
            cdo.id = base.id
            return self
        }
        
        public func build() -> HMCDDummy3 {
            return cdo
        }
    }
}

public class Dummy3 {
    public var id: String
    
    init() {
        id = ""
    }
}

extension HMCDDummy3: HMCDType {}

extension HMCDDummy3: HMCDConvertibleType {
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id")
                .shouldBeOptional()
                .with(type: .stringAttributeType)
                .build()
        ]
    }
}

extension Dummy3: HMCDParsableType {
    public typealias CDClass = HMCDDummy3
}
