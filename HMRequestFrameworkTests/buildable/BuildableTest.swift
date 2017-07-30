//
//  BuildableTest.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 7/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import XCTest
@testable import HMRequestFramework

public final class BuildableTest: XCTestCase {
    public func test_builderInstanceMethod_shouldWork() {
        /// 1
        let v1 = Model1.builder()
            .with(a1: "String1")
            .with(a2: 1)
            .with(a3: 2)
            .build()
        
        let v2 = v1.cloneBuilder().build()
        print(v1, v2)
        XCTAssertEqual(v1, v2)
        
        /// 2
        let v3 = v2.cloneBuilder().with(a1: "String2").build()
        let v4 = v3.cloneBuilder().with(a1: "String1").build()
        print(v2, v4)
        XCTAssertEqual(v2, v4)
        
        /// 3
        let v5 = v4.cloneBuilder().with(a1: "String2").with(a2: 2).build()
        let v6 = v5.cloneBuilder().with(a2: 1).build()
        print(v3, v6)
        XCTAssertEqual(v3, v6)
    }
}

public protocol Model1Type {
    var a1: String? { get set }
    var a2: Int? { get set }
    var a3: Double? { get set }
}

public struct Model1: Model1Type {
    public var a1: String?
    public var a2: Int?
    public var a3: Double?
}

extension Model1: HMProtocolConvertibleType {
    public typealias PTCType = Model1Type
    
    public func asProtocol() -> PTCType {
        return self as PTCType
    }
}

extension Model1: Equatable {
    public static func ==(lhs: Model1, rhs: Model1) -> Bool {
        return
            lhs.a1 == lhs.a1 &&
            lhs.a2 == lhs.a2 &&
            lhs.a3 == lhs.a3
    }
}

extension Model1: HMBuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate var model: Model1 = Model1()
        
        public func with(a1: String?) -> Builder {
            model.a1 = a1
            return self
        }
        
        public func with(a2: Int?) -> Builder {
            model.a2 = a2
            return self
        }
        
        public func with(a3: Double?) -> Builder {
            model.a3 = a3
            return self
        }
    }
}

extension Model1.Builder: HMProtocolConvertibleBuilderType {
    public typealias Buildable = Model1
    
    public func with(generic: Buildable.PTCType) -> Buildable.Builder {
        return self
            .with(a1: generic.a1)
            .with(a2: generic.a2)
            .with(a3: generic.a3)
    }
    
    public func with(buildable: Buildable) -> Buildable.Builder {
        return with(generic: buildable)
    }
    
    public func build() -> Buildable {
        return model
    }
}
