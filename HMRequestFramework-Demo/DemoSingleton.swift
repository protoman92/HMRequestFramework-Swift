//
//  DemoSingleton.swift
//  HMRequestFramework-Demo
//
//  Created by Hai Pham on 28/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMRequestFramework

public final class DemoSingleton {
  public static let cdManager = Singleton.coreDataManager(.background, .SQLite)
  public static let dbProcessor = Singleton.dbProcessor(DemoSingleton.cdManager)

  private init() {}
}
