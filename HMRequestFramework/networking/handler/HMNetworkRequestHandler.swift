//
//  HMNetworkRequestHandler.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import RxCocoa
import RxSwift
import SwiftFP
import SwiftUtilities

/// Use this class to perform network requests.
public struct HMNetworkRequestHandler {
  fileprivate var nwUrlSession: URLSession?
  fileprivate var rqmManager: HMFilterMiddlewareManager<Req>?
  fileprivate var sseManager: HMSSEManager?
  fileprivate var emManager: HMGlobalMiddlewareManager<HMErrorHolder>?

  fileprivate init() {}

  fileprivate func urlSession() -> URLSession {
    if let urlSession = self.nwUrlSession {
      return urlSession
    } else {
      fatalError("URLSession cannot be nil")
    }
  }

  public func eventSourceManager() -> HMSSEManager {
    if let sseManager = self.sseManager {
      return sseManager
    } else {
      fatalError("Event source manager cannot be nil")
    }
  }

  /// Execute a data request.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  fileprivate func executeData(_ request: Req) throws -> Observable<Try<Data>> {
    Preconditions.checkNotRunningOnMainThread(request)
    let urlSession = self.urlSession()
    let urlRequest = try request.urlRequest()
    let retries = request.retries()
    let delay = request.retryDelay()

    return urlSession.rx.data(request: urlRequest)
      .delayRetry(retries: retries, delay: delay)
      .map(Try.success)
      .catchErrorJustReturn(Try.failure)
  }
}

extension HMNetworkRequestHandler: HMNetworkRequestHandlerType {
  public typealias Req = HMNetworkRequest

  /// Override this method to provide default implementation.
  ///
  /// - Returns: A HMFilterMiddlewareManager instance.
  public func requestMiddlewareManager() -> HMFilterMiddlewareManager<Req>? {
    return rqmManager
  }

  /// Override this method to provide default implementation.
  ///
  /// - Returns: A HMFilterMiddlewareManager instance.
  public func errorMiddlewareManager() -> HMFilterMiddlewareManager<HMErrorHolder>? {
    return emManager
  }

  /// Perform a network request.
  ///
  /// - Parameters previous: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  public func execute(_ request: Req) throws -> Observable<Try<Data>> {
    Preconditions.checkNotRunningOnMainThread(request)
    return try executeData(request)
  }

  /// Open a SSE stream.
  ///
  /// - Parameter:
  ///   - request: A Req instance.
  ///   - qos: The QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  public func executeSSE(_ request: Req, _ qos: DispatchQoS.QoSClass) throws
    -> Observable<Try<[HMSSEvent<HMSSEData>]>>
  {
    let sseManager = self.eventSourceManager()
    let sseRequest = request.asSSERequest()
    return sseManager.openConnection(sseRequest, qos).map(Try.success)
  }

  /// Execute an upload request.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  public func executeUpload(_ request: Req) throws -> Observable<Try<UploadResult>> {
    Preconditions.checkNotRunningOnMainThread(request)
    let urlSession = self.urlSession()

    /// We only get the base URLRequest because for an upload operation, no
    /// request body is required.
    let urlRequest = try request.baseUrlRequest()
    let uploadTask: Observable<UploadResult>

    if let data = request.uploadData() {
      uploadTask = urlSession.rx.uploadWithCompletion(urlRequest, data)
    } else if let url = request.uploadURL() {
      uploadTask = urlSession.rx.uploadWithCompletion(urlRequest, url)
    } else {
      throw Exception("No Data available for upload")
    }

    let retries = request.retries()
    let delay = request.retryDelay()

    return uploadTask
      .delayRetry(retries: retries, delay: delay)
      .map(Try.success)
      .catchErrorJustReturn(Try.failure)
  }
}

extension HMNetworkRequestHandler: HMBuildableType {
  public static func builder() -> Builder {
    return Builder()
  }

  public class Builder {
    public typealias Req = HMNetworkRequestHandler.Req
    fileprivate var handler: Buildable

    fileprivate init() {
      handler = HMNetworkRequestHandler()
    }

    /// Set the URLSession instance.
    ///
    /// - Parameter urlSession: A URLSession instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(urlSession: URLSession?) -> Self {
      handler.nwUrlSession = urlSession
      return self
    }

    /// Set the request middleware manager instance.
    ///
    /// - Parameter rqmManager: A HMFilterMiddlewareManager instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(rqmManager: HMFilterMiddlewareManager<Req>?) -> Self {
      handler.rqmManager = rqmManager
      return self
    }

    /// Set the error middleware manager.
    ///
    /// - Parameter emManager: A HMGlobalMiddlewareManager instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(emManager: HMGlobalMiddlewareManager<HMErrorHolder>?) -> Self {
      handler.emManager = emManager
      return self
    }

    /// Set the SSE manager.
    ///
    /// - Parameter sseManager: A HMSSEManager instance.
    /// - Returns: The current Builder instance.
    @discardableResult
    public func with(sseManager: HMSSEManager?) -> Self {
      handler.sseManager = sseManager
      return self
    }
  }
}

extension HMNetworkRequestHandler.Builder: HMBuilderType {
  public typealias Buildable = HMNetworkRequestHandler

  /// Override this method to provide default implementation.
  ///
  /// - Parameter buildable: A HMNetworkRequestHandler instance
  /// - Returns: The current Builder instance.
  @discardableResult
  public func with(buildable: Buildable?) -> Self {
    if let buildable = buildable {
      return self
        .with(urlSession: buildable.nwUrlSession)
        .with(rqmManager: buildable.rqmManager)
        .with(emManager: buildable.emManager)
        .with(sseManager: buildable.sseManager)
    } else {
      return self
    }
  }

  public func build() -> Buildable {
    return handler
  }
}
