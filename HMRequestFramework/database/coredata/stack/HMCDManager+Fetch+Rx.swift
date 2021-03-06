//
//  HMCDManager+Fetch+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

public extension HMCDManager {

  /// Get the predicate to search for records related to a Sequence of
  /// identifiables.
  ///
  /// - Parameter data: A Sequence of HMCDIdentifiableType.
  /// - Returns: A NSPredicate instance.
  func predicateForIdentifiableFetch<S>(_ identifiables: S) -> NSPredicate where
    S: Sequence, S.Element == HMIdentifiableType
  {
    return NSCompoundPredicate(orPredicateWithSubpredicates:
      HMIdentifiables
        .segment(identifiables)
        .filter({!$0.1.isEmpty})
        .map({NSPredicate(format: "%K in %@", $0.0, $0.1)})
    )
  }

  /// Get the predicate to search for records related to a Sequence of
  /// identifiables.
  ///
  /// - Parameter data: A Sequence of HMCDIdentifiableType.
  /// - Returns: A NSPredicate instance.
  func predicateForIdentifiableFetch<S>(_ identifiables: S) -> NSPredicate where
    S: Sequence, S.Element: HMIdentifiableType
  {
    let identifiables = identifiables.map({$0 as HMIdentifiableType})
    return predicateForIdentifiableFetch(identifiables)
  }

  /// Get the sort descriptions to sort an identifiable fetch.
  ///
  /// - Parameter identifiables: A Sequence of HMCDIdentifiableType.
  /// - Returns: An Array of NSSortDescriptor.
  func sortForIdentifiableFetch<S>(_ identifiables: S) -> [NSSortDescriptor] where
    S: Sequence, S.Element == HMIdentifiableType
  {
    let pk = identifiables.first(where: {$0.primaryValue() != nil})?.primaryKey()
    return [NSSortDescriptor(key: pk, ascending: true)]
  }

  /// Get the sort descriptions to sort an identifiable fetch.
  ///
  /// - Parameter identifiables: A Sequence of HMCDIdentifiableType.
  /// - Returns: An Array of NSSortDescriptor.
  func sortForIdentifiableFetch<S>(_ identifiables: S) -> [NSSortDescriptor] where
    S: Sequence, S.Element: HMIdentifiableType
  {
    let identifiables = identifiables.map({$0 as HMIdentifiableType})
    return sortForIdentifiableFetch(identifiables)
  }
}

public extension HMCDManager {

  /// Fetch data from a context using a request. This operation blocks.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  func blockingFetch<Val>(_ context: Context,
                          _ request: NSFetchRequest<Val>) throws -> [Val] {
    return try context.fetch(request)
  }

  /// Fetch data from a context using a request and a specified Val class.
  /// This operation blocks.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - cls: A Val class type.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails
  func blockingFetch<Val>(_ context: Context,
                          _ request: NSFetchRequest<Val>,
                          _ cls: Val.Type) throws -> [Val] {
    return try blockingFetch(context, request)
  }

  /// Fetch data from a context using a request and a specified PureObject class.
  /// This operation blocks.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - cls: A PO class type.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails
  func blockingFetch<PO>(_ context: Context,
                         _ request: NSFetchRequest<PO.CDClass>,
                         _ cls: PO.Type) throws -> [PO.CDClass]
    where PO: HMCDPureObjectType
  {
    return try blockingFetch(context, request, cls.CDClass.self)
  }

  /// Refetch some NSManagedObject from DB. This operation blocks.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - data: A Sequence of NSManagedObject.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  func blockingRefetch<S>(_ context: Context, _ data: S) throws
    -> [NSManagedObject] where
    S: Sequence, S.Element: NSManagedObject
  {
    return try data.map({$0.objectID}).flatMap(context.existingObject)
  }
}

public extension HMCDManager {

  /// Fetch objects from DB whose primary key values correspond to those
  /// supplied by the specified identifiables objects.
  ///
  /// This method is defined to support many different generics. To specify
  /// the generics, simply declare another method that uses this method and
  /// specify class types for iCls and rCls.
  ///
  /// For example, the Sequence Element could be HMCDIdentifiableType or
  /// one of its subtype.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  ///   - predicate: The NSPredicate instance to query the identifiables.
  ///   - iCls: The identifiable class type.
  ///   - rCls: The type to cast the results to.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  private func blockingFetchIdentifiables<S,SS,ID,FR>(
    _ context: Context,
    _ entityName: String,
    _ ids: S,
    _ predicate: NSPredicate,
    _ sortDescriptors: SS,
    _ iCls: ID.Type,
    _ rCls: FR.Type) throws -> [FR] where
    FR: NSFetchRequestResult,
    S: Sequence, S.Element == ID,
    SS: Sequence, SS.Element == NSSortDescriptor
  {
    Preconditions.checkNotRunningOnMainThread(entityName)

    if ids.underestimatedCount > 0 {
      let request: NSFetchRequest<FR> = NSFetchRequest(entityName: entityName)
      request.predicate = predicate
      request.sortDescriptors = sortDescriptors.map({$0})
      return try blockingFetch(context, request)
    } else {
      return []
    }
  }

  /// Fetch objects from DB whose primary key values correspond to those
  /// supplied by the specified identifiables objects. The Sequence Element
  /// is HMCDIdentifiableType.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  ///   - rCls: The type to cast the results to.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  private func blockingFetchIdentifiables<S,FR>(
    _ context: Context,
    _ entityName: String,
    _ ids: S,
    _ rCls: FR.Type) throws -> [FR] where
    FR: NSFetchRequestResult,
    S: Sequence,
    S.Element == HMCDIdentifiableType
  {
    let identifiables = ids.map({$0 as HMIdentifiableType})
    let predicate = predicateForIdentifiableFetch(identifiables)
    let sorts = sortForIdentifiableFetch(identifiables)

    return try blockingFetchIdentifiables(
      context,
      entityName,
      ids,
      predicate,
      sorts,
      HMCDIdentifiableType.self,
      rCls
    )
  }

  /// Fetch objects from DB whose primary key values correspond to those
  /// supplied by the specified identifiables objects. The Sequence Element
  /// is a HMCDIdentifiableType subtype.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  ///   - rCls: The type to cast the results to.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  private func blockingFetchIdentifiables<U,S,FR>(_ context: Context,
                                                  _ entityName: String,
                                                  _ ids: S,
                                                  _ rCls: FR.Type) throws -> [FR] where
    U: HMCDIdentifiableType,
    FR: NSFetchRequestResult,
    S: Sequence,
    S.Element == U
  {
    let ids = ids.map({$0 as HMCDIdentifiableType})
    return try blockingFetchIdentifiables(context, entityName, ids, rCls)
  }

  /// Fetch objects from DB based on the specified identifiables objects. The
  /// result is then cast to the same type as that belonging to the identifiables.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  func blockingFetchIdentifiables<U,S>(_ context: Context,
                                       _ entityName: String,
                                       _ ids: S) throws -> [U] where
    U: NSFetchRequestResult,
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U
  {
    return try blockingFetchIdentifiables(context, entityName, ids, U.self)
  }

  /// Fetch objects from DB based on the specified identifiables objects. The
  /// result is then cast to NSManagedObject.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  func blockingFetchIdentifiables<U,S>(_ context: Context,
                                       _ entityName: String,
                                       _ ids: S) throws -> [NSManagedObject] where
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U
  {
    let rCls = NSManagedObject.self
    return try blockingFetchIdentifiables(context, entityName, ids, rCls)
  }

  /// Fetch objects from DB based on the specified identifiables objects. The
  /// result is then cast to NSManagedObject.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  /// - Returns: An Array of NSManagedObject.
  /// - Throws: Exception if the fetch fails.
  func blockingFetchIdentifiables<S>(_ context: Context,
                                     _ entityName: String,
                                     _ ids: S) throws -> [NSManagedObject] where
    S: Sequence, S.Element == HMCDIdentifiableType
  {
    let rCls = NSManagedObject.self
    return try blockingFetchIdentifiables(context, entityName, ids, rCls)
  }
}

public extension HMCDManager {

  /// Fetch some CoreData objects and observe the process.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - opMode: A HMCDOperationMode instance.
  ///   - obs: An ObserverType instance.
  /// - Returns: A Disposable instance.
  func fetch<Val,O>(_ context: Context,
                    _ request: NSFetchRequest<Val>,
                    _ opMode: HMCDOperationMode,
                    _ obs: O) -> Disposable where
    O: ObserverType, O.E == [Val]
  {
    Preconditions.checkNotRunningOnMainThread(request)

    performOperation(opMode, {
      do {
        let result = try self.blockingFetch(context, request)
        obs.onNext(result)
        obs.onCompleted()
      } catch let e {
        obs.onError(e)
      }
    })

    return Disposables.create()
  }

  /// Fetch identifiables and observe the process.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value.
  ///   - ids: A Sequence of identifiables.
  ///   - opMode: A HMCDOperationMode instance.
  ///   - obs: An ObserverType instance.
  /// - Returns: A Disposable instance.
  func fetchIdentifiables<U,S,O>(_ context: HMCDManager.Context,
                                 _ entityName: String,
                                 _ ids: S,
                                 _ opMode: HMCDOperationMode,
                                 _ obs: O) -> Disposable where
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U,
    O: ObserverType,
    O.E == [NSManagedObject]
  {
    Preconditions.checkNotRunningOnMainThread(entityName)

    performOperation(opMode, {
      do {
        let result = try self.blockingFetchIdentifiables(context, entityName, ids)
        obs.onNext(result)
        obs.onCompleted()
      } catch let e {
        obs.onError(e)
      }
    })

    return Disposables.create()
  }

  /// Fetch identifiables and observe the process.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value.
  ///   - ids: A Sequence of identifiables.
  ///   - opMode: A HMCDOperationMode instance.
  ///   - obs: An ObserverType instance.
  /// - Returns: A Disposable instance.
  func fetchIdentifiables<U,S,O>(_ context: HMCDManager.Context,
                                 _ entityName: String,
                                 _ ids: S,
                                 _ opMode: HMCDOperationMode,
                                 _ obs: O) -> Disposable where
    U: NSFetchRequestResult,
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U,
    O: ObserverType,
    O.E == [U]
  {
    Preconditions.checkNotRunningOnMainThread(entityName)

    performOperation(opMode, {
      do {
        let result = try self.blockingFetchIdentifiables(context, entityName, ids)
        obs.onNext(result)
        obs.onCompleted()
      } catch let e {
        obs.onError(e)
      }
    })

    return Disposables.create()
  }
}

public extension Reactive where Base == HMCDManager {

  /// Get data for a fetch request.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - opMode: A HMCDOperationMode instance.
  /// - Returns: An Observable instance.
  public func fetch<Val>(_ context: HMCDManager.Context,
                         _ request: NSFetchRequest<Val>,
                         _ opMode: HMCDOperationMode = .queued)
    -> Observable<[Val]>
  {
    return Observable.create({self.base.fetch(context, request, opMode, $0)})
  }

  /// Get data for a fetch request.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - cls: A Val class type.
  ///   - opMode: A HMCDOperationMode instance.
  /// - Returns: An Observable instance.
  public func fetch<Val>(_ context: HMCDManager.Context,
                         _ request: NSFetchRequest<Val>,
                         _ cls: Val.Type,
                         _ opMode: HMCDOperationMode = .queued)
    -> Observable<[Val]>
  {
    return fetch(context, request, opMode)
  }

  /// Get data for a fetch request.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - request: A NSFetchRequest instance.
  ///   - cls: A PO class type.
  ///   - opMode: A HMCDOperationMode instance.
  /// - Returns: An Observable instance.
  public func fetch<PO>(_ context: HMCDManager.Context,
                        _ request: NSFetchRequest<PO.CDClass>,
                        _ cls: PO.Type,
                        _ opMode: HMCDOperationMode = .queued)
    -> Observable<[PO.CDClass]> where PO: HMCDPureObjectType
  {
    return fetch(context, request, cls.CDClass.self, opMode)
  }

  /// Perform a refetch request for a Sequence of identifiable objects without
  /// any casting.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  ///   - opMode: A HMCDOperationMode instance.
  /// - Returns: An Observable instance.
  public func fetchIdentifiables<U,S>(_ context: HMCDManager.Context,
                                      _ entityName: String,
                                      _ ids: S,
                                      _ opMode: HMCDOperationMode = .queued)
    -> Observable<[NSManagedObject]> where
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U
  {
    return Observable.create({
      self.base.fetchIdentifiables(context, entityName, ids, opMode, $0)
    })
  }

  /// Perform a refetch request for a Sequence of identifiable objects and
  /// cast the result to the correct type.
  ///
  /// - Parameters:
  ///   - context: A Context instance.
  ///   - entityName: A String value representing the entity's name.
  ///   - ids: A Sequence of HMCDIdentifiableType.
  ///   - opMode: A HMCDOperationMode instance.
  /// - Returns: An Observable instance.
  public func fetchIdentifiables<U,S>(_ context: HMCDManager.Context,
                                      _ entityName: String,
                                      _ ids: S,
                                      _ opMode: HMCDOperationMode = .queued)
    -> Observable<[U]> where
    U: NSFetchRequestResult,
    U: HMCDIdentifiableType,
    S: Sequence,
    S.Element == U
  {
    return Observable.create({
      self.base.fetchIdentifiables(context, entityName, ids, opMode, $0)
    })
  }
}
