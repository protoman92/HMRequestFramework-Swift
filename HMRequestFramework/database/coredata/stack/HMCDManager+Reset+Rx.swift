//
//  HMCDManager+Reset+Rx.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 22/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities

public extension HMCDManager {
    
    /// Reset stores using the store coordinator. This operation is not thread-safe.
    ///
    /// - Throws: Exception if the reset fails.
    func resetStoresUnsafely() throws {
        let coordinator = storeCoordinator()
        let stores = coordinator.persistentStores
        
        if stores.isNotEmpty {
            try stores.forEach(coordinator.remove)
            try applyStoreSettings(coordinator, self.settings)
        }
    }
    
    /// Reset some context to its initial state. This operation is not thread-safe.
    ///
    /// - Parameter context: A Context instance.
    func resetContextUnsafely(_ context: Context) {
        context.reset()
    }
}

public extension HMCDManager {
    
    /// Reset some context to its initial state and observe the process.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - opMode: A HMCDOperationMode instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func resetContext<O>(_ context: Context,
                         _ opMode: HMCDOperationMode,
                         _ obs: O) -> Disposable where
        O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        
        performOperation(context, .perform, opMode, {
            self.resetContextUnsafely(context)
            obs.onNext(())
            obs.onCompleted()
        })
        
        return Disposables.create()
    }
    
    /// Reset stores and observer the process.
    ///
    /// - Parameter
    ///   - obs: An ObserverType instance.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Returns: A Disposable instance.
    func resetStores<O>(_ opMode: HMCDOperationMode, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        let coordinator = storeCoordinator()
        
        performOperation(coordinator, .perform, opMode, {
            do {
                try self.resetStoresUnsafely()
                obs.onNext(())
                obs.onCompleted()
            } catch let e {
                obs.onError(e)
            }
        })
        
        return Disposables.create()
    }
}

extension Reactive where Base == HMCDManager {
    
    /// Reset some context reactively.
    ///
    /// - Parameters:
    ///   - context: A Context instance.
    ///   - opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    func resetContext(_ context: HMCDManager.Context,
                      _ opMode: HMCDOperationMode = .queued) -> Observable<Void> {
        return Observable.create({self.base.resetContext(context, opMode, $0)})
    }
    
    /// Reset stores reactively.
    ///
    /// - Parameters opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    func resetStores(_ opMode: HMCDOperationMode = .queued) -> Observable<Void> {
        return Observable.create({self.base.resetStores(opMode, $0)})
    }
    
    /// Reset the entire stack by resetting contexts and wipe the DB.
    ///
    /// - Parameters opMode: A HMCDOperationMode instance.
    /// - Returns: An Observable instance.
    public func resetStack(_ opMode: HMCDOperationMode = .queued) -> Observable<Void> {
        let base = self.base
        
        return Observable
            .concat(
                resetContext(base.mainObjectContext(), opMode),
                resetContext(base.privateObjectContext(), opMode),
                
                // Store reset must not happen on the main thread.
                resetStores(opMode)
            )
            .reduce((), accumulator: {(_, _) in ()})
    }
}
