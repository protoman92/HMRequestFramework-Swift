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
/// - persistInMemory: Save operation. This saves some data to memory.
/// - persistToFile: Save operation. This saves some data to the local DB file.
/// - delete: Delete operation. This deletes some data from the local DB file.
/// - upsert: Update or insert. Persist new data and update existing data.
public enum CoreDataOperation {
    case fetch
    case persistInMemory
    case persistToFile
    case delete
    case upsert
}
