//
//  HMCDManager+Save+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

public extension HMCDManager {
    
    /// Save changes in a context. This operation is not thread-safe.
    ///
    /// - Parameter context: A Context instance.
    /// - Throws: Exception if the save fails.
    func saveUnsafely(_ context: Context) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    /// Persist all changes to DB.
    ///
    /// - Throws: Exception if the operation fails.
    func persistChangesUnsafely() throws {
        try saveUnsafely(mainObjectContext())
        try saveUnsafely(privateObjectContext())
    }
}

public extension HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjects: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    func saveUnsafely<S>(_ context: Context, _ pureObjects: S) throws where
        
        // For some reasons, XCode 8 cannot compile if we define a separate
        // generics for S.Iterator.Element. Although this is longer, it works
        // for both XCode 8 and 9.
        S: Sequence,
        S.Iterator.Element: HMCDPureObjectType,
        S.Iterator.Element.CDClass: HMCDObjectBuildableType,
        S.Iterator.Element.CDClass.Builder.PureObject == S.Iterator.Element
    {
        let pureObjects = pureObjects.map({$0})
        
        if pureObjects.isNotEmpty {
            let _ = try pureObjects.map({try self.constructUnsafely(context, $0)})
            try saveUnsafely(context)
        }
    }
}

public extension HMCDManager {
    
    /// Convert a Sequence of convertible objects into their NSManagedObject
    /// representations.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the operation fails.
    func convert<S>(_ context: Context, _ convertibles: S) -> [HMCDResult] where
        S: Sequence, S.Iterator.Element == HMCDObjectConvertibleType
    {
        var results: [HMCDResult] = []
        
        for item in convertibles {
            let result: HMCDResult
            
            do {
                _ = try item.asManagedObject(context)
                result = HMCDResult.just(item)
            } catch let e {
                result = HMCDResult.builder()
                    .with(object: item)
                    .with(error: e)
                    .build()
            }
            
            results.append(result)
        }
        
        return results
    }
    
    /// Convert a Sequence of convertible objects into their NSManagedObject
    /// representations. The result will be cast to some HMCDConvertibleType subtype.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the operation fails.
    func convert<U,S>(_ context: Context, _ convertibles: S) -> [HMCDResult] where
        U: HMCDObjectConvertibleType, S: Sequence, S.Iterator.Element == U
    {
        return convert(context, convertibles.map({$0 as HMCDObjectConvertibleType}))
    }
}

public extension HMCDManager {
    
    /// Persist all changes to DB and observe the process.
    ///
    /// - Parameter
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func persistChanges<O>(_ opMode: HMCDOperationMode, _ obs: O)
        -> Disposable where O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        
        performOperation(opMode, {
            do {
                try self.persistChangesUnsafely()
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
    
    /// Save context changes and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func save<O>(_ context: Context,
                 _ opMode: HMCDOperationMode,
                 _ obs: O) -> Disposable
        where O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        
        performOperation(opMode, {
            do {
                try self.saveUnsafely(context)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
    
    /// Construct a Sequence of CoreData from data objects, save it to the
    /// database and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjects: A Sequence of HMCDPureObjectType.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func savePureObjects<S,PO,O>(_ context: Context,
                                 _ pureObjects: S,
                                 _ opMode: HMCDOperationMode,
                                 _ obs: O) -> Disposable where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO,
        O: ObserverType,
        O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(pureObjects)
        
        performOperation(opMode, {
            do {
                try self.saveUnsafely(context, pureObjects)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    /// These objects will first be converted to a NSManagedObject and inserted
    /// into the specified context.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func saveConvertibles<S,O>(_ context: Context,
                               _ convertibles: S,
                               _ opMode: HMCDOperationMode,
                               _ obs: O) -> Disposable where
        S: Sequence,
        S.Iterator.Element == HMCDObjectConvertibleType,
        O: ObserverType,
        O.E == [HMCDResult]
    {
        Preconditions.checkNotRunningOnMainThread(convertibles)
        
        performOperation(opMode, {
            let convertibles = convertibles.map({$0})
            
            if convertibles.isNotEmpty {
                let results = self.convert(context, convertibles)
                
                do {
                    try self.saveUnsafely(context)
                    obs.onNext(results)
                    obs.onCompleted()
                } catch let e {
                    obs.onError(e)
                }
            } else {
                obs.onNext([])
                obs.onCompleted()
            }
        })
        
        return Disposables.create()
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func saveConvertibles<U,S,O>(_ context: Context,
                                 _ convertibles: S,
                                 _ opMode: HMCDOperationMode,
                                 _ obs: O) -> Disposable where
        U: HMCDObjectConvertibleType,
        S: Sequence, S.Iterator.Element == U,
        O: ObserverType, O.E == [HMCDResult]
    {
        let convertibles = convertibles.map({$0 as HMCDObjectConvertibleType})
        return saveConvertibles(context, convertibles, opMode, obs)
    }
}

public extension Reactive where Base == HMCDManager {
    
    /// Save changes for a Context.
    ///
    /// - Parameter
    ///   - context: A Context instance.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    public func save(_ context: HMCDManager.Context,
                     _ opMode: HMCDOperationMode = .queued) -> Observable<Void> {
        return Observable.create({self.base.save(context, opMode, $0)})
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - pureObjects: A Sequence of HMCDPureObjectType.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    public func savePureObjects<S,PO>(_ context: HMCDManager.Context,
                                      _ pureObjects: S,
                                      _ opMode: HMCDOperationMode = .queued)
        -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO
    {
        return Observable.create({
            self.base.savePureObjects(context, pureObjects, opMode, $0)
        })
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Return: An Observable instance.
    func saveConvertibles<S>(_ context: HMCDManager.Context,
                             _ convertibles: S,
                             _ opMode: HMCDOperationMode = .queued)
        -> Observable<[HMCDResult]> where
        S: Sequence, S.Iterator.Element == HMCDObjectConvertibleType
    {
        return Observable.create({
            self.base.saveConvertibles(context, convertibles, opMode, $0)
        })
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Return: An Observable instance.
    func saveConvertibles<S,OC>(_ context: HMCDManager.Context,
                                _ convertibles: S,
                                _ opMode: HMCDOperationMode = .queued)
        -> Observable<[HMCDResult]> where
        OC: HMCDObjectConvertibleType,
        S: Sequence, S.Iterator.Element == OC
    {
        let convertibles = convertibles.map({$0 as HMCDObjectConvertibleType})
        return saveConvertibles(context, convertibles, opMode)
    }
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Parameters opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    public func persistLocally(_ opMode: HMCDOperationMode = .queued) -> Observable<Void> {
        return Observable.create({self.base.persistChanges(opMode, $0)})
    }
}
