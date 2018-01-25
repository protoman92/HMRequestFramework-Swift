//: Playground - noun: a place where people can play

import RxSwift
import SwiftUtilities
import PlaygroundFramework

public final class A: BuildableType, Equatable {
    public typealias Builder = ABuilder
    
    public static func builder() -> ABuilder {
        return ABuilder()
    }
    
    public static func ==(lhs: A, rhs: A) -> Bool {
        return lhs.a1 == rhs.a1 && lhs.a2 == rhs.a2
    }
    
    fileprivate var a1: String?
    fileprivate var a2: Int?
}

public final class ABuilder: BuilderType {
    public typealias Buildable = A
    
    private let a: A
    
    fileprivate init() {
        a = A()
    }
    
    public func with(a1: String?) -> Self {
        a.a1 = a1
        return self
    }
    
    public func with(a2: Int?) -> Self {
        a.a2 = a2
        return self
    }
    
    public func with(buildable: A?) -> Self {
        return buildable
            .map({self.with(a1: $0.a1).with(a2: $0.a2)})
            .getOrElse(self)
    }
    
    public func build() -> A {
        return a
    }
}

let a = A.builder().with(a1: "123").with(a2: 1).build()
let b = a.cloneBuilder().with(a1: "456").build()
a == b
