//
//  HMProtocolConvertibleType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Classes that implement this protocol should have a protocol associated
/// type. For example, class Dummy should be convertible to DummyType.
///
/// We can use this with result processors to convert concrete types into
/// their protocol representation.
public protocol HMProtocolConvertibleType {
    associatedtype PTCType
}
