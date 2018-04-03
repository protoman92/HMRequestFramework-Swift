//
//  HMNetworkRequestHandlerType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/22/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxSwift
import SwiftFP

/// Classes that implement this protocol must be able to handle network requests.
public protocol HMNetworkRequestHandlerType: HMRequestHandlerType, HMNetworkRequestAliasType {

  /// Perform a network request.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  func execute(_ request: Req) throws -> Observable<Try<Data>>

  /// Open a SSE stream.
  ///
  /// - Parameter:
  ///   - request: A Req instance.
  ///   - qos: The QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  func executeSSE(_ request: Req, _ qos: DispatchQoS.QoSClass) throws
    -> Observable<Try<[HMSSEvent<HMSSEData>]>>

  /// Perform an upload request.
  ///
  /// - Parameter req: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  func executeUpload(_ req: Req) throws -> Observable<Try<UploadResult>>
}

public extension HMNetworkRequestHandlerType {

  /// Perform a network request.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - qos: The QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func execute<Prev>(_ previous: Try<Prev>,
                            _ generator: @escaping HMRequestGenerator<Prev,Req>,
                            _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<Data>>
  {
    return execute(previous, generator, execute, qos)
  }

  /// Open a SSE stream.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - qos: The QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func executeSSE<Prev>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[HMSSEvent<HMSSEData>]>>
  {
    return execute(previous, generator, {try self.executeSSE($0, qos)}, qos)
  }

  /// Perfor an upload request.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - qos: The QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func executeUpload<Prev>(_ previous: Try<Prev>,
                                  _ generator: @escaping HMRequestGenerator<Prev,Req>,
                                  _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<UploadResult>>
  {
    return execute(previous, generator, executeUpload, qos)
  }
}
