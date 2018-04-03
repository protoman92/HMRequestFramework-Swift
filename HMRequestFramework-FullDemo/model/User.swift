//
//  User.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import CoreData
import HMRequestFramework

/// In a parallel object model, a single entity comprises 3 objects:
///
///  - The managed object (which we prefix with CD).
///  - The pure object.
///  - The pure object builder (which is necessary for immutability).
///
/// I'd say the most tedious step of adopting this framework is the translation
/// of object models into this one. Usage of the framework is straightforward
/// after that.
public protocol UserType {
  var id: String? { get }
  var name: String? { get }
  var age: NSNumber? { get }
  var visible: NSNumber? { get }
  var updatedAt: Date? { get }
}

public extension UserType {
  public func primaryKey() -> String {
    return "id"
  }

  public func primaryValue() -> String? {
    return id
  }

  public func stringRepresentationForResult() -> String {
    return id.getOrElse("")
  }
}

public final class CDUser: NSManagedObject {
  @NSManaged public var id: String?
  @NSManaged public var name: String?
  @NSManaged public var age: NSNumber?
  @NSManaged public var visible: NSNumber?
  @NSManaged public var updatedAt: Date?
}

public struct User {
  public static let updatedAtKey = "updatedAt"

  fileprivate var _id: String?
  fileprivate var _name: String?
  fileprivate var _age: NSNumber?
  fileprivate var _visible: NSNumber?
  fileprivate var _updatedAt: Date?

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

  public var updatedAt: Date? {
    return _updatedAt
  }

  fileprivate init() {
    _updatedAt = Date()
  }
}

///////////////////////////////// EXTENSIONS /////////////////////////////////

extension CDUser: UserType {}

//extension CDUser: HMCDObjectMasterType {

/// Version control to enable optimistic locking.
extension CDUser: HMCDVersionableMasterType {
  public typealias PureObject = User

  public static func cdAttributes() throws -> [NSAttributeDescription]? {
    return [
      NSAttributeDescription.builder()
        .with(name: "id")
        .with(type: .stringAttributeType)
        .with(optional: false)
        .build(),

      NSAttributeDescription.builder()
        .with(name: "name")
        .with(type: .stringAttributeType)
        .with(optional: false)
        .build(),

      NSAttributeDescription.builder()
        .with(name: "age")
        .with(type: .integer64AttributeType)
        .with(optional: false)
        .build(),

      NSAttributeDescription.builder()
        .with(name: "visible")
        .with(type: .booleanAttributeType)
        .with(optional: false)
        .build(),

      NSAttributeDescription.builder()
        .with(name: "updatedAt")
        .with(type: .dateAttributeType)
        .with(optional: false)
        .build(),
    ]
  }

  /// This is where we update the current managed object to mutate it in
  /// the internal disposable context.
  public func mutateWithPureObject(_ object: PureObject) {
    id = object.id
    name = object.name
    age = object.age
    visible = object.visible
    updatedAt = object.updatedAt
  }

  fileprivate func versionDateFormat() -> String {
    return "yyyy/MM/dd hh:mm:ss a"
  }

  fileprivate func formatDateForVersioning(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = versionDateFormat()
    return formatter.string(from: date)
  }

  fileprivate func convertVersionToDate(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = versionDateFormat()
    return formatter.date(from: string)
  }

  /// Implement the version update with updateAt date flag.
  public func currentVersion() -> String? {
    return updatedAt.map({formatDateForVersioning($0)})
  }

  public func oneVersionHigher() -> String? {
    return formatDateForVersioning(Date())
  }

  public func hasPreferableVersion(over obj: HMVersionableType) throws -> Bool {
    let date = obj.currentVersion().flatMap({convertVersionToDate($0)})
    return updatedAt.zipWith(date, {$0 >= $1}).getOrElse(false)
  }

  public func mergeWithOriginalVersion(_ obj: HMVersionableType) throws {
    name = "MergedDueToVersionConflict"
    age = 999
  }

  public func updateVersion(_ version: String?) throws {
    updatedAt = version.flatMap({convertVersionToDate($0)})
  }
}

extension User: UserType {}

extension User: HMCDPureObjectMasterType {
  public typealias CDClass = CDUser

  public static func builder() -> Builder {
    return Builder()
  }

  public final class Builder: HMCDPureObjectBuilderMasterType {
    public typealias Buildable = User

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

    /// Do not allow external modifications since this is also used for
    /// version control.
    fileprivate func with(updatedAt date: Date?) -> Self {
      user._updatedAt = date
      return self
    }

    public func with(user: UserType?) -> Self {
      return user.map({self
        .with(id: $0.id)
        .with(name: $0.name)
        .with(age: $0.age)
        .with(visible: $0.visible)
        .with(updatedAt: $0.updatedAt)
      }).getOrElse(self)
    }

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
}

extension User: CustomStringConvertible {
  public var description: String {
    return id.getOrElse("No id present")
  }
}

extension User: Equatable {
  public static func ==(lhs: User, rhs: User) -> Bool {
    return true
      && lhs.id == rhs.id
      && lhs.name == rhs.name
      && lhs.age == rhs.age
      && lhs.visible == rhs.visible
      && lhs.updatedAt == rhs.updatedAt
  }
}
