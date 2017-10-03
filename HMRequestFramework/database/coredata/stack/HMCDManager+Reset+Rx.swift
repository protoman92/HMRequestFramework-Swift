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
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func resetContext<O>(_ context: Context, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Void
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        
        performOnQueue(context) {
            self.resetContextUnsafely(context)
            obs.onNext(())
            obs.onCompleted()
        }
        
        return Disposables.create()
    }
    
    /// Reset stores and observer the process.
    ///
    /// - Parameter obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func resetStores<O>(_ obs: O) -> Disposable where O: ObserverType, O.E == Void {
        Preconditions.checkNotRunningOnMainThread(nil)
        let coordinator = storeCoordinator()
        
        coordinator.perform({
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
    /// - Parameter context: A Context instance.
    /// - Returns: An Observable instance.
    func resetContext(_ context: HMCDManager.Context) -> Observable<Void> {
        return Observable.create({self.base.resetContext(context, $0)})
    }
    
    /// Reset stores reactively.
    ///
    /// - Returns: An Observable instance.
    func resetStores() -> Observable<Void> {
        return Observable.create({self.base.resetStores($0)})
    }
    
    /// Reset the entire stack by resetting contexts and wipe the DB.
    ///
    /// - Returns: An Observable instance.
    public func resetStack() -> Observable<Void> {
        let base = self.base
        
        return Observable
            .concat(
                resetContext(base.mainObjectContext()),
                resetContext(base.privateObjectContext()),
                
                // Store reset must not happen on the main thread.
                resetStores()
            )
            .reduce((), accumulator: {_ in ()})
    }
}
