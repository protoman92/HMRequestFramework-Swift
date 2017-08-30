//
//  HMCDOperation.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// This enum represents the different operations that CoreData can carry
/// out.
///
/// - fetch: Fetch operation.
/// - deleteData: Delete operation. This deletes some data from memory.
/// - deleteBatch: Batch delete operation. This only works for SQLite stores.
/// - saveData: Save operation. This saves some convertible objects to memory.
/// - persistLocally: Save operation. This saves some data to the local DB file.
/// - upsert: Update or insert. Persist new data and update existing data.
/// - resetStack: Wipe DB and reset the stack.
/// - stream: Stream DB changes.
public enum HMCDOperation: EnumerableType {
    // For this operation, the request should contain:
    //  - entityName
    //  - operation
    //  - predicate (optional)
    //  - sortDescriptors (optional)
    //  - fetchLimit (optional)
    //  - fetchResultType (optional)
    //  - fetchProperties (optional)
    //  - fetchGroupBy (optional)
    case fetch
    
    // For this operation, the request should contain:
    //  - entityName
    //  - operation
    //  - deletedData
    case deleteData
    
    // For this operation, the request should contain:
    //  - entityName
    //  - operation
    //  - predicate
    case deleteBatch
    
    // For this operation, the request should contain:
    //  - entityName
    //  - operation
    //  - savedData
    case saveData
    
    // For this operation, the request should contain:
    //  - operation
    case persistLocally
    
    // For this operation, the request should contain:
    //  - entityName
    //  - operation
    //  - upsertedData
    //  - versionConflictStrategy
    case upsert
    
    // For this operation, the request should contain:
    //  - operation.
    case resetStack
    
    // For this operation, the request should contain similar parameters as if
    // it were a fetch request.
    case stream
    
    public static func allValues() -> [HMCDOperation] {
        return [
            .fetch,
            .deleteData,
            .deleteBatch,
            .saveData,
            .persistLocally,
            .upsert,
            .resetStack,
            .stream
        ]
    }
}
