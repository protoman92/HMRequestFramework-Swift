//
//  Singleton.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 24/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public final class Singleton {
    public static func coreDataManager() -> HMCDManager {
        let fileManager = FileManager.default
        
        let url = HMCDPersistentStoreURL.builder()
            .with(fileManager: fileManager)
            .withDocumentDirectory()
            .withUserDomainMask()
            .with(fileName: "HMRequestFramework")
            .with(storeType: .SQLite)
            .build()
        
        print("Creating store at \(try! url.storeURL())")
        
        try? fileManager.removeItem(at: try! url.storeURL())
        
        let settings = [
            HMCDPersistentStoreSettings.builder()
                .with(storeType: .InMemory)
                .with(persistentStoreURL: url)
                .build()
        ]
        
        let constructor = HMCDConstructor.builder()
            .with(cdTypes: Dummy1.CDClass.self, Dummy2.CDClass.self)
            .with(settings: settings)
            .build()
        
        return try! HMCDManager(constructor: constructor)
    }
    
    public static func dbProcessor(_ manager: HMCDManager) -> HMCDRequestProcessor {
        let rqMiddlewareManager = HMMiddlewareManager<HMCDRequest>.builder().build()
        
        return HMCDRequestProcessor.builder()
            .with(manager: manager)
            .with(rqMiddlewareManager: rqMiddlewareManager)
            .build()
    }
}
