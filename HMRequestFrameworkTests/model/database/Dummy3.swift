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
        let entity = try HMCDDummy3.entityDescription(in: context)
        self.init(entity: entity, insertInto: nil)
    }
}

extension HMCDDummy3: HMCDBuildableType {
    public static func builder(_ context: NSManagedObjectContext) throws -> Builder {
        return try Builder(HMCDDummy3(context))
    }
    
    public final class Builder: HMCDBuilderType {
        public typealias Base = Dummy3
        
        private let cdo: HMCDDummy3
        
        fileprivate init(_ cdo: HMCDDummy3) {
            self.cdo = cdo
        }
        
        public func with(base: Dummy3) -> Self {
            cdo.id = base.id
            return self
        }
        
        public func build() -> HMCDDummy3 {
            return cdo
        }
    }
}

extension HMCDDummy3: HMCDRepresentableType {
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id")
                .shouldNotBeOptional()
                .with(type: .stringAttributeType)
                .build()
        ]
    }
}

extension HMCDDummy3: HMCDPureObjectConvertibleType {
    public typealias PureObject = Dummy3
}

public class Dummy3 {
    public var id: String
    
    init() {
        id = String.random(withLength: 100)
    }
}

extension Dummy3: HMCDPureObjectType {
    public typealias CDClass = HMCDDummy3
}

extension Dummy3: HMCDPureObjectBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder: HMCDPureObjectBuilderType {
        public typealias Buildable = Dummy3
        
        private let dummy = Dummy3()
        
        public func with(representable: HMCDDummy3) -> Self {
            dummy.id = representable.id
            return self
        }
        
        public func with(buildable: Dummy3) -> Self {
            dummy.id = buildable.id
            return self
        }
        
        public func build() -> Dummy3 {
            return dummy
        }
    }
}
