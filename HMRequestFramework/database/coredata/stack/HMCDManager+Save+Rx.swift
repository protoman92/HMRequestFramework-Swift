//
//  HMCDManager+Save.swift
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
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Throws: Exception if the save fails.
    func saveUnsafely(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    /// Persist all changes to DB.
    ///
    /// - Throws: Exception if the operation fails.
    func persistChangesUnsafely() throws {
        try saveUnsafely(mainContext)
        try saveUnsafely(privateContext)
    }
}

public extension HMCDManager {
    
    /// Persist all changes to DB and observe the process.
    ///
    /// - Parameter obs: An ObserverType instance.
    func persistChanges<O>(_ obs: O) where O: ObserverType, O.E == Void {
        performOnContextThread(mainContext) {
            do {
                try self.persistChangesUnsafely()
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - pureObjects: A Sequence of HMCDPureObjectType.
    /// - Throws: Exception if the save fails.
    func saveUnsafely<S>(_ context: NSManagedObjectContext,
                         _ pureObjects: S) throws where
        // For some reasons, XCode 8 cannot compile if we define a separate
        // generics for S.Iterator.Element. Although this is longer, it works
        // for both XCode 8 and 9.
        S: Sequence,
        S.Iterator.Element: HMCDPureObjectType,
        S.Iterator.Element.CDClass: HMCDObjectBuildableType,
        S.Iterator.Element.CDClass.Builder.PureObject == S.Iterator.Element
    {
        let _ = try pureObjects.map({try self.constructUnsafely(context, $0)})
        try saveUnsafely(context)
    }
}

public extension HMCDManager {
    
    /// Save context changes and observe the process.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - obs: An ObserverType instance.
    func save<O>(_ context: NSManagedObjectContext, _ obs: O)
        where O: ObserverType, O.E == Void
    {
        performOnContextThread(mainContext) {
            do {
                try self.saveUnsafely(context)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension HMCDManager {
    
    /// Convert a Sequence of convertible objects into their NSManagedObject
    /// representations.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the operation fails.
    func convert<S>(_ context: NSManagedObjectContext,
                    _ convertibles: S) -> [HMResult] where
        S: Sequence, S.Iterator.Element == HMCDConvertibleType
    {
        var results: [HMResult] = []
        
        for item in convertibles {
            let result: HMResult
            
            do {
                _ = try item.asManagedObject(context)
                result = HMResult.just(item)
            } catch let e {
                result = HMResult.builder().with(object: item).with(error: e).build()
            }
            
            results.append(result)
        }
        
        return results
    }
    
    /// Convert a Sequence of convertible objects into their NSManagedObject
    /// representations. The result will be cast to some HMCDConvertibleType subtype.
    ///
    /// - Parameters:
    ///   - context: A NSManagedObjectContext instance.
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    /// - Returns: An Array of HMResult.
    /// - Throws: Exception if the operation fails.
    func convert<U,S>(_ context: NSManagedObjectContext,
                      _ convertibles: S) -> [HMResult] where
        U: HMCDConvertibleType, S: Sequence, S.Iterator.Element == U
    {
        return convert(context, convertibles.map({$0 as HMCDConvertibleType}))
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    /// These objects will first be converted to a NSManagedObject and inserted
    /// into the specified context.
    ///
    /// - Parameters:
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - obs: An ObserverType instance.
    func save<S,O>(_ convertibles: S, _ obs: O) where
        S: Sequence, S.Iterator.Element == HMCDConvertibleType,
        O: ObserverType, O.E == [HMResult]
    {
        let context = disposableObjectContext()
        
        performOnContextThread(context) {
            let results = self.convert(context, convertibles)
            
            do {
                try self.saveUnsafely(context)
                obs.onNext(results)
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters:
    ///   - convertibles: A Sequence of HMCDConvertibleType.
    ///   - obs: An ObserverType instance.
    func save<U,S,O>(_ convertibles: S, _ obs: O) where
        U: HMCDConvertibleType,
        S: Sequence, S.Iterator.Element == U,
        O: ObserverType, O.E == [HMResult]
    {
        return save(convertibles.map({$0 as HMCDConvertibleType}), obs)
    }
}

public extension HMCDManager {
    
    /// Construct a Sequence of CoreData from data objects, save it to the
    /// database and observe the process.
    ///
    /// - Parameters:
    ///   - pureObjects: A Sequence of HMCDPureObjectType.
    ///   - obs: An ObserverType instance.
    /// - Throws: Exception if the save fails.
    public func save<S,PO,O>(_ pureObjects: S, _ obs: O) where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence,
        S.Iterator.Element == PO,
        O: ObserverType,
        O.E == Void
    {
        let context = disposableObjectContext()
        
        performOnContextThread(mainContext) {
            do {
                try self.saveUnsafely(context, pureObjects)
                obs.onNext()
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        }
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save changes for a NSManagedObjectContext.
    ///
    /// - Parameter context: A NSManagedObjectContext instance.
    /// - Returns: An Observable instance.
    public func save(_ context: NSManagedObjectContext) -> Observable<Void> {
        return Observable.create({(obs: AnyObserver<Void>) in
            self.base.save(context, obs)
            return Disposables.create()
        })
    }
    
    /// Construct a Sequence of CoreData from data objects and save it to memory.
    ///
    /// - Parameters pureObjects: A Sequence of HMCDPureObjectType.
    /// - Returns: An Observable instance.
    public func save<S,PO>(_ pureObjects: S) -> Observable<Void> where
        PO: HMCDPureObjectType,
        PO.CDClass: HMCDObjectBuildableType,
        PO.CDClass.Builder.PureObject == PO,
        S: Sequence, S.Iterator.Element == PO
    {
        return Observable.create(({(obs: AnyObserver<Void>) in
            self.base.save(pureObjects, obs)
            return Disposables.create()
        }))
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters convertibles: A Sequence of HMCDConvertibleType.
    /// - Return: An Observable instance.
    func save<S>(_ convertibles: S) -> Observable<[HMResult]> where
        S: Sequence, S.Iterator.Element == HMCDConvertibleType
    {
        return Observable<[HMResult]>.create({
            self.base.save(convertibles, $0)
            return Disposables.create()
        })
    }
    
    /// Save a Sequence of convertible objects to memory and observe the process.
    ///
    /// - Parameters convertibles: A Sequence of HMCDConvertibleType.
    /// - Return: An Observable instance.
    func save<S,OC>(_ convertibles: S)
        -> Observable<[HMResult]> where
        OC: HMCDConvertibleType,
        S: Sequence, S.Iterator.Element == OC
    {
        return save(convertibles.map({$0 as HMCDConvertibleType}))
    }
}

public extension Reactive where Base: HMCDManager {
    
    /// Save all changes in the main and private contexts. When the main context
    /// is saved, the changes will be reflected in the private context, so we
    /// need to save the former first.
    ///
    /// - Returns: An Observable instance.
    public func persistLocally() -> Observable<Void> {
        return Observable<Void>.create({
            self.base.persistChanges($0)
            return Disposables.create()
        })
    }
}
