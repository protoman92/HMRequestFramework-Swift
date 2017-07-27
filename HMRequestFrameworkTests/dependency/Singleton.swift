//
//  Singleton.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 7/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMRequestFramework

public final class Singleton {
    public static func cdManager() -> HMCDManager {
        return dummyCDManager()
    }
    
    public static func dummyCDSettings() -> [HMPersistentStoreSettings] {
        return [
            HMPersistentStoreSettings.builder().with(storeType: .InMemory).build()
        ]
    }
    
    public static func dummyCDConstructor() -> HMCDConstructor {
        return HMCDConstructor.builder()
            .with(convertibles: Dummy1.self, Dummy2.self)
            .with(settings: dummyCDSettings())
            .build()
    }
    
    public static func dummyCDManager() -> ErrorCDManager {
        return try! ErrorCDManager(constructor: dummyCDConstructor())
    }
    
    private init() {}
}
