//
//  SingletonType.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 17/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxSwift
import SwiftUtilities

/// We use forced unwraps here because if this singleton fails to initialize,
/// there's no point in continuing running the app anyway - so it's better to
/// just crash.
///
/// Under normal circumstances, forced unwraps should be avoided at all costs.
public protocol SingletonType {
    var dbRequestManager: HMCDRequestProcessor { get }
    var trackedObjectManager: TrackedObjectManager { get }
}

public final class Singleton: SingletonType {
    private static var _instance: SingletonType?
    
    public static var instance: SingletonType {
        var instance = _instance
        
        synchronized(self, then: {
            if instance == nil {
                _instance = Singleton(.SQLite)
                instance = _instance
            }
        })
        
        return instance!
    }
    
    public static func create(_ storeType: HMCDStoreSettings.StoreType) -> Singleton {
        return Singleton(storeType)
    }
    
    fileprivate var _dbRequestManager: HMCDRequestProcessor
    fileprivate var _trackedObjectManager: TrackedObjectManager
    
    public var dbRequestManager: HMCDRequestProcessor {
        return _dbRequestManager
    }
    
    public var trackedObjectManager: TrackedObjectManager {
        return _trackedObjectManager
    }
    
    private init(_ storeType: HMCDStoreSettings.StoreType) {
        let cdURL = HMCDStoreURL.builder()
            .with(fileName: "FullDemo")
            .with(domainMask: .userDomainMask)
            .with(searchPath: .documentDirectory)
            .with(storeType: .SQLite)
            .withDefaultFileManager()
            .build()
        
        let cdSettings = HMCDStoreSettings.builder()
            .with(storeType: storeType)
            .with(persistentStoreURL: cdURL)
            .build()
        
        let cdConstructor = HMCDConstructor.builder()
            .with(cdTypes: CDUser.self)
            .with(mainContextMode: .background)
            .with(settings: cdSettings)
            .build()
        
        let cdManager = try! HMCDManager(constructor: cdConstructor)
        
        let rqMiddlewareManager = HMFilterMiddlewareManager<HMCDRequest>.builder()
            .add(transform: {
                Observable.just($0.cloneBuilder().with(retries: 3).build())
            }, forKey: "RetryMiddleware")
            .add(transform: {
                Observable.just($0.cloneBuilder().with(vcStrategy: .error).build())
            }, forKey: "VCMiddleware")
            .add(sideEffect: {print($0)}, forKey: "LogMiddleware")
            .build()
        
        let errMiddlewareManager = HMGlobalMiddlewareManager<HMErrorHolder>.builder()
            .add(sideEffect: {print($0.localizedDescription)})
            .build()
        
        _dbRequestManager = HMCDRequestProcessor.builder()
            .with(manager: cdManager)
            .with(rqmManager: rqMiddlewareManager)
            .with(emManager: errMiddlewareManager)
            .build()
        
        _trackedObjectManager = TrackedObjectManager(_dbRequestManager)
    }
}
