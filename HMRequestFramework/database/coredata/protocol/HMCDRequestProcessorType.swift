//
//  HMCDRequestProcessorType.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/22/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftFP

/// Classes that implement this protocol must be able to perform CoreData
/// requests and process the result.
public protocol HMCDRequestProcessorType: HMRequestHandlerType, HMCDGeneralRequestProcessorType {

  /// Perform a CoreData get request with required dependencies. This method
  /// should be used for CoreData operations whose results are constrained
  /// to some NSManagedObject subtype.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  func executeTyped<Val>(_ request: Req) throws -> Observable<Try<[Val]>>
  where Val: NSFetchRequestResult

  /// Perform a CoreData save request with required dependencies. This
  /// method returns an Observable that emits the success/failure status of
  /// each item that is saved.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  /// - Throws: Exception if the operation fails.
  func executeTyped(_ request: Req) throws -> Observable<Try<[HMCDResult]>>

  /// Perform a CoreData request with required dependencies.
  ///
  /// This method should be used with operations that do not require specific
  /// result type, e.g. CoreData save requests.
  ///
  /// - Parameter request: A Req instance.
  /// - Returns: An Observable instance.
  func execute(_ request: Req) throws -> Observable<Try<Void>>
}

public extension HMCDRequestProcessorType {

  /// Perform a CoreData typed request, which returns an Observable that emits
  /// a Try containing an Array of some result, and process the result.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: A HMRequestGenerator instance.
  ///   - perform: A HMRequestPerformer instance.
  ///   - processor: A HMResultProcessor instance.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  private func processArray<Prev,Val,Res>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ perform: @escaping HMRequestPerformer<Req,[Val]>,
    _ processor: @escaping HMResultProcessor<Val,Res>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[Try<Res>]>>
  {
    return execute(previous, generator, perform, qos)
      .map({try $0.getOrThrow()})

      // We need to process the CoreData objects right within the vals Array,
      // instead of using Observable.from and process each emission individually,
      // because it could lead to properties being reset to nil (ARC-releated).
      .flatMap({(vals: [Val]) -> Observable<[Try<Res>]> in
        return Observable.just(vals)
          .flatMapSequence({$0.map({(val) -> Observable<Try<Res>> in
            do {
              return try processor(val).subscribeOnConcurrent(qos: qos)
            } catch let e {
              return Observable.just(Try.failure(e))
            }
          })})
          .flatMap({$0})
          .catchErrorJustReturn(Try.failure)
          .toArray()
      })
      .map(Try.success)
      .catchErrorJustReturn(Try.failure)
  }

  /// Perform a CoreData get request and process the result.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - processor: Processor function to process the request result.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func processTyped<Prev,Val,Res>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ processor: @escaping HMResultProcessor<Val,Res>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[Try<Res>]>> where Val: NSFetchRequestResult
  {
    return processArray(previous, generator, executeTyped, processor, qos)
  }

  /// Perform a CoreData result-based request and process the result. Each
  /// HMCDResult represents the success/failure of the operation on one
  /// particular item.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - processor: Processor function to process the request result.
  /// - Returns: An Observable instance.
  public func processTyped<Prev,Res>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ processor: @escaping HMResultProcessor<HMCDResult,Res>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[Try<Res>]>>
  {
    return processArray(previous, generator, executeTyped, processor, qos)
  }

  /// Perform a CoreData result-based request and process the result using
  /// a default processor. Since HMResult and Try have similarities in terms
  /// of semantics, we can simply use HMResult directly in the emission.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func processResult<Prev>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[HMCDResult]>>
  {
    let processor = HMResultProcessors.eqProcessor(HMCDResult.self)

    return processTyped(previous, generator, processor, qos)
      .map({$0.map({$0.map(HMCDResult.unwrap)})})
  }

  /// Perform a CoreData get request and process the result into a pure object.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - poCls: The PureObject class type.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func processPureObject<Prev,PO>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ poCls: PO.Type,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<[PO]>> where
    PO: HMCDPureObjectType,
    PO.CDClass: NSManagedObject,
    PO.CDClass: HMCDPureObjectConvertibleType,
    PO.CDClass.PureObject == PO
  {
    let processor = HMCDResultProcessors.pureObjectPs(poCls)

    return processTyped(previous, generator, processor, qos)

      // Since asPureObject() does not throw an error, we can safely
      // assume the processing succeeds for all items.
      .map({$0.map({$0.compactMap({$0.value})})})
  }

  /// This method should be used for all operations other than those which
  /// require specific NSManagedObject subtypes.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - processor: Processor function to process the request result.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func processVoid<Prev,Res>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ processor: @escaping HMResultProcessor<Void,Res>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<Res>>
  {
    return execute(previous, generator, execute, qos)
      .flatMap({try HMResultProcessors.processResultFn($0, processor)})
  }

  /// This method should be used for all operations other than those which
  /// require specific NSManagedObject subtypes. Cast the result to Void using
  /// a default processor.
  ///
  /// - Parameters:
  ///   - previous: The result of the upstream request.
  ///   - generator: Generator function to create the current request.
  ///   - qos: A QoSClass instance to perform work on.
  /// - Returns: An Observable instance.
  public func processVoid<Prev>(
    _ previous: Try<Prev>,
    _ generator: @escaping HMRequestGenerator<Prev,Req>,
    _ qos: DispatchQoS.QoSClass)
    -> Observable<Try<Void>>
  {
    let processor = {(_: Any) in Observable.just(Try.success(()))}
    return processVoid(previous, generator, processor, qos)
  }
}

