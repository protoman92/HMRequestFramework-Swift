//
//  User.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import CoreData
import HMRequestFramework

public protocol UserType {
    var id: String? { get }
    var name: String? { get }
    var age: NSNumber? { get }
    var visible: NSNumber? { get }
}

public extension UserType {
    public func primaryKey() -> String {
        return "id"
    }
    
    public func primaryValue() -> String? {
        return id
    }
}

public final class CDUser: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var age: NSNumber?
    @NSManaged public var visible: NSNumber?
    
    public convenience init(_ context: Context) throws {
        let entity = try CDUser.entityDescription(in: context)
        self.init(entity: entity, insertInto: context)
    }
}

extension CDUser: UserType {}

extension CDUser: HMCDObjectMasterType {
    public typealias PureObject = User
    
    public static func cdAttributes() throws -> [NSAttributeDescription]? {
        return [
            NSAttributeDescription.builder()
                .with(name: "id")
                .with(type: .stringAttributeType)
                .with(optional: false)
                .with(defaultValue: UUID().uuidString)
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "name")
                .with(type: .stringAttributeType)
                .with(optional: false)
                .with(defaultValue: UUID().uuidString)
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "age")
                .with(type: .integer16AttributeType)
                .with(optional: false)
                .with(defaultValue: UUID().uuidString)
                .build(),
            
            NSAttributeDescription.builder()
                .with(name: "visible")
                .with(type: .booleanAttributeType)
                .with(optional: false)
                .with(defaultValue: UUID().uuidString)
                .build(),
        ]
    }
    
    public func mutateWithPureObject(_ object: PureObject) {
        id = object.id
        name = object.name
        age = object.age
        visible = object.visible
    }
}

public struct User {
    fileprivate var _id: String?
    fileprivate var _name: String?
    fileprivate var _age: NSNumber?
    fileprivate var _visible: NSNumber?
    
    public var id: String? {
        return _id
    }
    
    public var name: String? {
        return _name
    }
    
    public var age: NSNumber? {
        return _age
    }
    
    public var visible: NSNumber? {
        return _visible
    }
}

extension User: UserType {}

extension User: HMCDPureObjectMasterType {
    public typealias CDClass = CDUser
    
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var user: Buildable
        
        public init() {
            user = User()
        }
        
        public func with(id: String?) -> Self {
            user._id = id
            return self
        }
        
        public func with(name: String?) -> Self {
            user._name = name
            return self
        }
        
        public func with(age: NSNumber?) -> Self {
            user._age = age
            return self
        }
        
        public func with(visible: NSNumber?) -> Self {
            user._visible = visible
            return self
        }
        
        public func with(user: UserType?) -> Self {
            return user.map({self
                .with(id: $0.id)
                .with(name: $0.name)
                .with(age: $0.age)
                .with(visible: $0.visible)
            }).getOrElse(self)
        }
    }
}

extension User.Builder: HMCDPureObjectBuilderMasterType {
    public typealias Buildable = User
    
    public func with(buildable: Buildable?) -> Self {
        return with(user: buildable)
    }
    
    public func with(cdObject: Buildable.CDClass) -> Self {
        return with(user: cdObject)
    }
    
    public func build() -> Buildable {
        return user
    }
}
