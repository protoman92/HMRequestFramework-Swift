//
//  VersionConflictStrategy.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// This class contains convenient enums to deal with version conflicts.
public final class VersionConflict {
    
    /// Specify the strategy to apply when a version conflict is encountered.
    ///
    /// - error: Throw an Error.
    /// - ignore: Ignore and continue the update.
    public enum Strategy {
        case error
        case ignore
    }
    
    private init() {}
}
