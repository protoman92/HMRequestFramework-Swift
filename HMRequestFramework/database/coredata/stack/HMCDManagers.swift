//
//  HMCDManagers.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/24/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

extension HMCDManager: HMCDRxManagerType {}
extension HMCDManager: ReactiveCompatible {}

public extension HMCDObjectConstructorType where Self: HMCDManager {
    /// Construct a CoreData model object using the disposable context.
    ///
    /// - Parameters cls: A CD class type.
    /// - Returns: A CD instance.
    /// - Throws: Exception if the construction fails.
    public func construct<CD>(_ cls: CD.Type) throws -> CD where
        CD: HMCDRepresentableType
    {
        return try construct(disposableObjectContext(), cls)
    }
    
    /// Construct a CoreData object from a data object, using the disposable
    /// context.
    ///
    /// - Parameter pureObj: A PO instance.
    /// - Returns: A PO.CDClass object.
    /// - Throws: Exception if the construction fails.
    public func construct<PO>(_ pureObj: PO) throws -> PO.CDClass where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO
    {
        return try construct(disposableObjectContext(), pureObj)
    }
    
    /// Convenient method to construct a CoreData model object from a data
    /// class using the disposable context.
    ///
    /// - Parameter pureObj: A PO class.
    /// - Returns: A PO.CDClass object.
    /// - Throws: Exception if the construction fails.
    public func construct<PO>(_ cls: PO.Type) throws -> PO.CDClass
        where PO: HMCDPureObjectType
    {
        return try construct(disposableObjectContext(), cls)
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save changes for a NSManagedObjectContext.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: An Observable instance.
    public func save(context: NSManagedObjectContext) -> Observable<Void> {
        return Observable.create({(obs: AnyObserver<Void>) in
            self.base.save(context: context, obs)
            return Disposables.create()
        })
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save data to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ context: NSManagedObjectContext,
                                _ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.saveInMemory(context, data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save data to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ context: NSManagedObjectContext,
                                _ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return saveInMemory(context, data.map({$0 as NSManagedObject}))
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func saveInMemory<S,PO>(_ context: NSManagedObjectContext,
                                   _ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.saveInMemory(context, data, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a lazily produced Sequence of data to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ context: NSManagedObjectContext,
                                _ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.saveInMemory(context, dataFn, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a lazily produced Sequence of data to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ context: NSManagedObjectContext,
                                _ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.saveInMemory(context, dataFn, obs)
            return Disposables.create()
        }))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save data to a disposable context.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return saveInMemory(base.disposableObjectContext(), data)
    }
    
    /// Save data to a disposable context.
    ///
    /// - Parameter data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return saveInMemory(data.map({$0 as NSManagedObject}))
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to the
    /// disposable context.
    ///
    /// - Parameter data: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func saveInMemory<S,PO>(_ data: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDRepresetableBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return saveInMemory(base.disposableObjectContext(), data)
    }
    
    /// Save a lazily produced Sequence of data to the disposable context.
    ///
    /// - Parameter dataFn: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return saveInMemory(base.disposableObjectContext(), dataFn)
    }
    
    /// Save a lazily produced Sequence of data to the disposable context.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A function that produces data.
    /// - Returns: An Observable instance.
    public func saveInMemory<S>(_ dataFn: @escaping () throws -> S)
        -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return saveInMemory(base.disposableObjectContext(), dataFn)
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Delete data from memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ context: NSManagedObjectContext,
                                    _ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.deleteFromMemory(context, data, obs)
            return Disposables.create()
        }))
    }
    
    /// Delete data from memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ context: NSManagedObjectContext,
                                    _ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        return deleteFromMemory(context, data.map({$0 as NSManagedObject}))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Delete data from memory.
    ///
    /// - Parameters data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element == NSManagedObject
    {
        return deleteFromMemory(base.disposableObjectContext(), data)
    }
    
    /// Delete data from memory.
    ///
    /// - Parameters data: A Sequence of NSManagedObject.
    /// - Returns: An Observable instance.
    public func deleteFromMemory<S>(_ data: S) -> Observable<Void> where
        S: Sequence, S.Iterator.Element: NSManagedObject
    {
        let context = base.disposableObjectContext()
        return deleteFromMemory(context, data.map({$0 as NSManagedObject}))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistAllChangesToFile() -> Observable<Void> {
        let mainContext = base.mainContext
        let privateContext = base.privateContext
        
        return Observable
            .concat(save(context: mainContext), save(context: privateContext))
            .reduce((), accumulator: {_ in ()})
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Get data for a fetch request.
    ///
    /// - Parameter request: A NSFetchRequest instance.
    /// - Returns: An Observable instance.
    public func fetch<Val>(_ request: NSFetchRequest<Val>) -> Observable<Val> {
        let base = self.base
        
        return Observable.create({(obs: AnyObserver<[Val]>) in
            do {
                let result = try base.blockingFetch(request)
                obs.onNext(result)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
            
            return Disposables.create()
        }).flatMap({Observable.from($0)})
    }
}
