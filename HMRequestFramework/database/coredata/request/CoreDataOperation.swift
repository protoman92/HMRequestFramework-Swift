//
//  CoreDataOperation.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// This enum represents the different operations that CoreData can carry
/// out.
///
/// - fetch: Fetch operation.
/// - save: Save operation. This simply saves changes to the inner context.
/// - saveData: Save operation. This saves some data to the local DB file.
public enum CoreDataOperation {
    case fetch
    case persist
    case persistData
}
